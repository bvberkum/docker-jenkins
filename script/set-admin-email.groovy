import jenkins.model.*

def jenkinsLocationConfiguration = JenkinsLocationConfiguration.get()

// FIXME admin email
jenkinsLocationConfiguration.setAdminAddress(
  "Jenkins name <jenkins@localhost>"
)

jenkinsLocationConfiguration.save()
