#!/bin/bash

CSV_FILE="users.csv"

while IFS=';' read -r nom prenom username email numero
do
    if [[ "$username" != "username" ]]; then
        echo "Creating role for $username to access only apm-${username}-* indices..."

        curl -X POST "http://172.31.1.23:9200/_security/role/$username" -H "Content-Type: application/json" -d "{
          \"cluster\": [\"monitor\"],
          \"indices\": [
            {
              \"names\": [\"apm-${username}-*\"],
              \"privileges\": [\"read\", \"manage\"]
            }
          ]
        }"
    fi
done < "$CSV_FILE"
