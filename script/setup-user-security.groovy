
import jenkins.model.*
import hudson.security.*
import hudson.markup.RawHtmlMarkupFormatter
import hudson.markup.EscapedMarkupFormatter

import hudson.security.SecurityRealm
import com.cloudbees.plugins.credentials.SystemCredentialsProvider
import org.jenkinsci.main.modules.cli.auth.ssh.UserPropertyImpl


// Get build vars from args by evaluating as groovy
def gshell = new GroovyShell(this.binding)
try { 
  for (i=0; i<args.size(); i++ ) {
    val = args[i]
    println val
    gshell.evaluate(val)
  }

// Or set defaults for non-interactive run, and parse vars from file if preset
} catch (MissingPropertyException e) {

  gshell.evaluate('''
   Build_Admin_User='jenkins'
   Build_Admin_Password='jenkins'
   Build_Admin_Overwrite=null
   Build_Admin_Public_Key=null
  ''')

  def JENKINS_HOME = System.getenv('JENKINS_HOME')
  File propF = new File("${JENKINS_HOME}/init.groovy.d/setup-user-security.init")

  if (propF.exists()) {
    def lines = propF.readLines()
    lines.each { gshell.evaluate(it) }
  }
}
if (Build_Admin_Overwrite == null) { Build_Admin_Overwrite = 1; }


def instance = Jenkins.getInstance()

// Enable security if not set
def hudsonRealm = instance.getSecurityRealm()

if (instance.getSecurityRealm() == SecurityRealm.NO_AUTHENTICATION) {

  hudsonRealm = new HudsonPrivateSecurityRealm(false)
  instance.setSecurityRealm(hudsonRealm)

  // Enable security
  def strategy = new hudson.security.FullControlOnceLoggedInAuthorizationStrategy()
  strategy.setAllowAnonymousRead(false)
  instance.setAuthorizationStrategy(strategy)
  instance.save()
}
// TODO: test, give this a try; may depend on matrix acl plugin?
//def strategy = new GlobalMatrixAuthorizationStrategy()
//strategy.add(Jenkins.ADMINISTER, Build_Admin_Password )
//instance.setAuthorizationStrategy(strategy)


// Create admin user with public-key if not exists
if (Build_Admin_Overwrite == 1 || hudsonRealm.getUser( Build_Admin_User ) ) {

  // Create user:passwd
  user = hudsonRealm.createAccount( Build_Admin_User, Build_Admin_Password )

  // Add public key
  if (Build_Admin_Public_Key != null ) {
    def system_creds = SystemCredentialsProvider.getInstance()
    keys = new org.jenkinsci.main.modules.cli.auth.ssh.UserPropertyImpl(
        Build_Admin_Public_Key )
    user.addProperty(keys)
  }

  user.save()
}

// Set formatter from default plain-text to safe-HTML

def globalSecConf = new GlobalSecurityConfiguration()

def formatter = globalSecConf.getMarkupFormatter()
if (formatter in EscapedMarkupFormatter) {
  instance.setMarkupFormatter(RawHtmlMarkupFormatter.INSTANCE)
  instance.save()
}

