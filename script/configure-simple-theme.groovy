/** 
 * Set the Simple-Theme to userContent.css/.js at startup.
 */

import hudson.model.*
import jenkins.model.*


for (pd in PageDecorator.all()) {
  if (pd instanceof org.codefirst.SimpleThemeDecorator) {
    pd.cssUrl = '/userContent/userContent.css'
    pd.jsUrl = '/userContent/userContent.js'
  }
}

// Id: docker-jenkins/0.0.5-dev script/configure-simple-theme.groovy
