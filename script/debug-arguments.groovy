import jenkins.model.*
import hudson.model.*

import com.cloudbees.plugins.credentials.Credentials
import com.cloudbees.plugins.credentials.CredentialsScope
import com.cloudbees.plugins.credentials.domains.Domain
import com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl
import com.cloudbees.plugins.credentials.SystemCredentialsProvider

import com.nirima.jenkins.plugins.docker.*
import com.nirima.jenkins.plugins.docker.launcher.*
import com.nirima.jenkins.plugins.docker.strategy.*


//println arguments , not working, but args is:
println args.size()
//println System.getenv()

for (i=0; i<args.size(); i++ ) {
  val = args[i]
  println val
}

