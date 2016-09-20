import jenkins.model.*
import hudson.model.*
import net.sf.*;
import net.sf.json.*;
import net.sf.json.groovy.*;
import groovy.json.*

import com.cloudbees.plugins.credentials.Credentials
import com.cloudbees.plugins.credentials.CredentialsScope
import com.cloudbees.plugins.credentials.domains.Domain
import com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl
import com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey
import com.cloudbees.plugins.credentials.SystemCredentialsProvider



// Get build vars from env by evaluating as groovy
def gshell = new GroovyShell(this.binding)

gshell.evaluate('''
  Update_Credentials_Clear=0
  Build_Credentials_Json_File='/configure-credentials.json'
''')

for (i=0; i<args.size(); i++ ) {
  val = args[i]
  println val
  gshell.evaluate(val)
}


println "Update_Credentials_Clear = ${Update_Credentials_Clear}"
println "Build_Credentials_Json_File = ${Build_Credentials_Json_File}"
println "Params parsed"


def system_creds = SystemCredentialsProvider.getInstance()

File jsonFile = new File(Build_Credentials_Json_File);
def parser = new JsonSlurper()
def credentials_settings = parser.parse(jsonFile)


Map<Domain, List<Credentials>> domainCredentialsMap = system_creds.getDomainCredentialsMap()


def resolve_cred_scope = { String scope ->
  // Scope: SYSTEM; Accessible for root Jenkins (ie. to launch slaves)
  // GLOBAL; or USER.
  switch (scope.toLowerCase()) {
    case "system": return CredentialsScope.SYSTEM
    case "global": return CredentialsScope.GLOBAL
    case "user": return CredentialsScope.USER
    default:
      assert false : "Unknown scope ${scope}"
  }
}


def resolve_key_source = { cred ->

  switch (cred.type) {

    case 'ssh-key-file':
      return new BasicSSHUserPrivateKey.FileOnMasterPrivateKeySource(cred['key-file'])
    case 'ssh-key-direct':
      return new BasicSSHUserPrivateKey.DirectEntryPrivateKeySource(cred.key)
    case 'ssh-key-user':
      return new BasicSSHUserPrivateKey.UsersPrivateKeySource()
    default:
      assert false : "Unknown cred.type ${cred.type}"
  }
}


def resolve_cred_json_spec = { cred ->

  def scope = resolve_cred_scope(cred.scope);


  switch (cred.type) {

    case 'username-password':
      return \
        new UsernamePasswordCredentialsImpl( scope,
          cred.id, cred.descr, cred.username, cred.password )


    case 'ssh-key-file':
    case 'ssh-key-direct':
    case 'ssh-key-user':
      def pkSrc = resolve_key_source cred

      return \
        new BasicSSHUserPrivateKey(
          scope, cred.id, cred.username, pkSrc, cred.passphrase,
          cred.description) 

    case 'docker-directory-credentials':
      if (cred.dir.equals(""))
        cred.dir = System.getenv('DOCKER_CERTIFICATES_DIRECTORY')
      return \
        new com.nirima.jenkins.plugins.docker.utils.DockerDirectoryCredentials(
          scope, cred.id, cred.description, cred.dir )


    default:
      assert false : "No a known cred-type: '${cred.type}'"
  }
}


credentials_settings.each { domain, creds ->

  def domain_
  if (domain.equals("")) {
    domain_ = Domain.global()
  } else {
    assert false : "Domains not implemented"
  }

  if (Update_Credentials_Clear == 1 ) {
    domainCredentialsMap[domain_].clear()
    println "Truncated existing '${domain}' domain credentials"
  }

  creds.each { cred ->
    obj = resolve_cred_json_spec( cred )
    println "New credential ${obj}"
    assert obj != null : "No object resolved for ${cred}"
    domainCredentialsMap[domain_].add( obj )
  }
}


system_creds.save()
println 'Added credentials.'

