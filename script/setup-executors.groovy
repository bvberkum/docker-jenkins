import jenkins.model.*

def instance = Jenkins.getInstance()


int executors;

try {
  executors = System.getenv("JENKINS_EXECUTORS").toInteger()
} catch (e) {
  executors = 1
}

instance.setNumExecutors(executors)

instance.save()
