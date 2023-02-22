import hudson.model.*
import hudson.security.*
import hudson.tasks.Mailer
import com.cloudbees.hudson.plugins.folder.*
import jenkins.model.Jenkins
import org.jenkinsci.plugins.matrixauth.AbstractAuthorizationPropertyConverter;
import org.jenkinsci.plugins.matrixauth.AmbiguityMonitor;
import org.jenkinsci.plugins.matrixauth.AuthorizationPropertyDescriptor;
import org.jenkinsci.plugins.matrixauth.AuthorizationProperty;
import org.jenkinsci.plugins.matrixauth.AuthorizationType;
import org.jenkinsci.plugins.matrixauth.PermissionEntry;
import org.jenkinsci.plugins.credentials.*;

def userId = args[0]
def password = args[1]
def email = args[2]
def instance = jenkins.model.Jenkins.instance
def existingUser = instance.securityRealm.allUsers.find {it.id == userId}
def strategy = new hudson.security.ProjectMatrixAuthorizationStrategy()


if (existingUser == null) {
   
    def user = instance.securityRealm.createAccount(userId, password)
    user.addProperty(new Mailer.UserProperty(email));


    def folderItem = jenkins.model.Jenkins.instance.createProject(Folder.class, userId)


    println "displayName = " + folderItem.displayName

    com.cloudbees.hudson.plugins.folder.properties.AuthorizationMatrixProperty prop;

    folderItem.properties.each { p -> 

        println "canonicalName = " + p.class.canonicalName

        if(p.class.canonicalName == "com.cloudbees.hudson.plugins.folder.properties.AuthorizationMatrixProperty") {

            prop = p;

        }
    } 

    String sID=  user.getId() ;

    boolean propIsNew = prop == null;
    
    if (propIsNew) {
        prop = new com.cloudbees.hudson.plugins.folder.properties.AuthorizationMatrixProperty();
    }

    prop.add(Item.READ, new PermissionEntry(AuthorizationType.USER, sID));
    prop.add(Item.BUILD, new PermissionEntry(AuthorizationType.USER, sID));
    prop.add(Item.CONFIGURE, new PermissionEntry(AuthorizationType.USER, sID));
    prop.add(Item.DELETE, new PermissionEntry(AuthorizationType.USER, sID));
    prop.add(Item.WORKSPACE, new PermissionEntry(AuthorizationType.USER, sID));
    prop.add(Item.CANCEL, new PermissionEntry(AuthorizationType.USER, sID));
    prop.add(Item.CREATE, new PermissionEntry(AuthorizationType.USER, sID));

    prop.add(Run.DELETE, new PermissionEntry(AuthorizationType.USER, sID));
    prop.add(Run.UPDATE, new PermissionEntry(AuthorizationType.USER, sID));

    prop.add(com.cloudbees.plugins.credentials.CredentialsProvider.VIEW, new PermissionEntry(AuthorizationType.USER, sID));
    prop.add(com.cloudbees.plugins.credentials.CredentialsProvider.CREATE, new PermissionEntry(AuthorizationType.USER, sID));
    prop.add(com.cloudbees.plugins.credentials.CredentialsProvider.DELETE, new PermissionEntry(AuthorizationType.USER, sID));
    prop.add(com.cloudbees.plugins.credentials.CredentialsProvider.MANAGE_DOMAINS, new PermissionEntry(AuthorizationType.USER, sID));
    prop.add(com.cloudbees.plugins.credentials.CredentialsProvider.UPDATE, new PermissionEntry(AuthorizationType.USER, sID));
    

    def inheritanceStrategy = new org.jenkinsci.plugins.matrixauth.inheritance.NonInheritingStrategy()

    prop.setInheritanceStrategy(inheritanceStrategy);


    try {
        if (propIsNew) {
            folderItem.addProperty(prop);
        } 
    } 
    catch (IOException ex) {
        LOGGER.log(Level.WARNING, "Failed to grant creator permissions on job " + item.getFullName(), ex);
    }


    folderItem.save() 
            

    println "  "
} 



Jenkins.instance.save()
