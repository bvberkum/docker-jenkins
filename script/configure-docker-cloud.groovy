import jenkins.model.*
import hudson.model.*
import net.sf.*;
import net.sf.json.*;
import net.sf.json.groovy.*;
import groovy.json.*

import com.nirima.jenkins.plugins.docker.*
import com.nirima.jenkins.plugins.docker.launcher.*
import com.nirima.jenkins.plugins.docker.strategy.*



// Get build vars from env by evaluating as groovy
def gshell = new GroovyShell(this.binding)

gshell.evaluate('''
  Update_Cloud_Clear=0
  Update_Cloud_Name='Local Docker'
  Swarm_Master_URL=null
  Build_Docker_Cloud_Json_File='/configure-docker-cloud.json'
''')

for (i=0; i<args.size(); i++ ) {
  val = args[i]
  println val
  gshell.evaluate(val)
}

if ( Swarm_Master_URL == null ) {
  Swarm_Master_URL = System.getenv "SWARM_MASTER_URL"
}

if ( Swarm_Master_URL == null ) {
  Swarm_Master_URL = System.getenv("DCKR_HOST")
  if ( Swarm_Master_URL != null ) {
    Swarm_Master_URL = Swarm_Master_URL.replace('tcp:', 'https:')
  }
}

assert Swarm_Master_URL != null : "Cannot determine Swarm_Master_URL"

println "Update_Cloud_Clear = ${Update_Cloud_Clear}"
println "Update_Cloud_Name = ${Update_Cloud_Name}"
println "Swarm_Master_URL = ${Swarm_Master_URL}"
println "Params parsed"


def resolve_pull_strategy = { strategy ->
  switch (strategy.toLowerCase()) {
    case "never":
      return DockerImagePullStrategy.PULL_NEVER
    case "always":
      return DockerImagePullStrategy.PULL_ALLWAS
    case "latest":
      return DockerImagePullStrategy.PULL_LATEST
  }
}

def resolve_node_mode = { mode ->
  switch (mode.toLowerCase()) {
    case "exclusive": return Node.Mode.EXCLUSIVE
    case "normal": return Node.Mode.NORMAL
  }
}

/////////////////////////////////////////////////////:
// Docker Cloud config per-se
/////////////////////////////////////////////////////:

if (Update_Cloud_Clear == 1 ) {
  Jenkins.instance.clouds.clear();
  println 'Truncated existing clouds.'
}

File jsonFile = new File(Build_Docker_Cloud_Json_File);
def parser = new JsonSlurper()
def docker_settings = parser.parse(jsonFile)

if (Update_Cloud_Name != null) {
  docker_settings[0]['name'] = Update_Cloud_Name
}
if (Swarm_Master_URL != null) {
  docker_settings[0]['serverUrl'] = Swarm_Master_URL
}

//JsonBuilder json = new JsonBuilder ()
//json docker_settings
//println json.toString()

def dockerClouds = []
docker_settings.each { cloud ->

  def templates = []
  cloud.templates.each { template ->

      def dockerTemplateBase =
          new DockerTemplateBase(
             template.image,
             template.dnsString,
             template.network,
             template.dockerCommand,
             template.volumesString,
             template.volumesFromString,
             template.environmentsString,
             template.lxcConfString,
             template.hostname,
             template.memoryLimit,
             template.memorySwap,
             template.cpuShares,
             template.bindPorts,
             template.bindAllPorts,
             template.privileged,
             template.tty,
             template.macAddress
          )

      def dockerTemplate =
        new DockerTemplate(
          dockerTemplateBase,
          template.labelString,
          template.remoteFs,
          template.remoteFsMapping,
          template.instanceCapStr
        )

      dockerTemplate.setMode(resolve_node_mode(template.mode))
      dockerTemplate.setNumExecutors(template.executors)
      dockerTemplate.setRemoveVolumes(template['remove-volumes'])
      dockerTemplate.setPullStrategy(resolve_pull_strategy(template['pull-strategy']))

      def dockerComputerSSHLauncher = new DockerComputerSSHLauncher(
          new hudson.plugins.sshslaves.SSHConnector(
            template.sshPort, template.credentialsId, null, null, null, null, null )
      )
      dockerTemplate.setLauncher(dockerComputerSSHLauncher)

      dockerTemplate.setRetentionStrategy(new DockerOnceRetentionStrategy(10))

      templates.add(dockerTemplate)
  }

  dockerClouds.add(
    new DockerCloud(cloud.name,
                    templates,
                    cloud.serverUrl,
                    cloud.containerCapStr,
                    cloud.connectTimeout ?: 15, // Well, it's one for the money...
                    cloud.readTimeout ?: 15,    // Two for the show
                    cloud.credentialsId,
                    cloud.version
    )
  )
}

Jenkins.instance.clouds.addAll(dockerClouds)

println 'Configured docker cloud.'

