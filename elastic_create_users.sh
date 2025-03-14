#!/bin/bash

# Fichier CSV contenant : nom;prenom;username;email;numero
CSV_FILE="isp_etu.csv"
ELASTIC_URL="http://172.31.1.23:9200"

# Vérifier que les variables d'environnement ELASTIC_USER et ELASTIC_PASSWORD sont définies
if [[ -z "$ELASTIC_USER" || -z "$ELASTIC_PASSWORD" ]]; then
    echo "❌ ERREUR: Définissez les variables ELASTIC_USER et ELASTIC_PASSWORD"
    exit 1
fi

while IFS=';' read -r nom prenom username email numero
do
    # Vérifier que l'username est valide
    if [[ -n "$username" && "$username" != "username" ]]; then
        echo "🔹 Vérification du rôle pour $username..."

        # Vérifier si le rôle existe déjà
        ROLE_EXISTS=$(curl -s -u "$ELASTIC_USER:$ELASTIC_PASSWORD" -X GET "$ELASTIC_URL/_security/role/$username" | jq -r ".$username")
        
        if [[ "$ROLE_EXISTS" == "null" ]]; then
            echo "✅ Création du rôle pour $username avec accès à apm-${username}-*"
            curl -s -u "$ELASTIC_USER:$ELASTIC_PASSWORD" -X POST "$ELASTIC_URL/_security/role/role-$username" \
            -H "Content-Type: application/json" -d "{
              \"indices\": [
                {
                  \"names\": [\"apm-${username}-*\"],
                  \"privileges\": [\"read\", \"view_index_metadata\", \"monitor\"]
                }
              ]
            }"
        else
            echo "⚠️ Rôle pour $username déjà existant, passage à l'utilisateur."
        fi

        # Vérifier si l'utilisateur existe déjà
        echo "🔹 Vérification de l'utilisateur $username..."
        USER_EXISTS=$(curl -s -u "$ELASTIC_USER:$ELASTIC_PASSWORD" -X GET "$ELASTIC_URL/_security/user/$username" | jq -r ".$username")

        if [[ "$USER_EXISTS" == "null" ]]; then
            PASSWORD=$(openssl rand -base64 12)  # Générer un mot de passe sécurisé aléatoire
            echo "✅ Création de l'utilisateur $username avec le rôle role-${username}"

            curl -s -u "$ELASTIC_USER:$ELASTIC_PASSWORD" -X POST "$ELASTIC_URL/_security/user/$username" \
            -H "Content-Type: application/json" -d "{
              \"password\": \"$PASSWORD\",
              \"roles\": [\"kibana_user\", \"role-${username}\"],
              \"full_name\": \"$prenom $nom\",
              \"email\": \"$email\"
            }"
            echo "🔑 Mot de passe temporaire pour $username : $PASSWORD"
        else
            echo "⚠️ Utilisateur $username déjà existant, aucun changement effectué."
        fi
    else
        echo "⚠️ Entrée invalide détectée dans le CSV, ignorée."
    fi
done < "$CSV_FILE"

echo "✅ Tous les rôles et utilisateurs ont été traités."
