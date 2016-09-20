// Not: Jenkins.instance.setNumExecutors(5)

import jenkins.model.*

def instance = Jenkins.getInstance()

instance.setNumExecutors(3)

instance.save()
