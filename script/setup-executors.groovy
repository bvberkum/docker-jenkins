// Not: Jenkins.instance.setNumExecutors(5)

import jenkins.model.*

def instance = Jenkins.getInstance()


int executors;

try {
  executors = System.getenv("JENKINS_EXECUTORS").toInteger()
} catch () {}

if (executors == null) {
  executors = 1
}

instance.setNumExecutors(executors)

instance.save()
