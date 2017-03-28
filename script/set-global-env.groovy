
instance = Jenkins.getInstance()
globalNodeProperties = instance.getGlobalNodeProperties()
envVarsNodePropertyList = globalNodeProperties.getAll(hudson.slaves.EnvironmentVariablesNodeProperty.class)

newEnvVarsNodeProperty = null
envVars = null
if ( envVarsNodePropertyList == null || envVarsNodePropertyList.size() == 0 )
{
  newEnvVarsNodeProperty = new hudson.slaves.EnvironmentVariablesNodeProperty();
  globalNodeProperties.add(newEnvVarsNodeProperty)
  envVars = newEnvVarsNodeProperty.getEnvVars()
} else {
  envVars = envVarsNodePropertyList.get(0).getEnvVars()
}

if (!envVars['BASH_ENV']) {
  envVars['BASH_ENV'] = '~/.conf/bash/env.sh'
  Jenkins.instance.save()  
}

// Id: docker-jenkins/0.0.5-dev script/set-global-env.groovy
