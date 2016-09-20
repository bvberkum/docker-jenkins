import jenkins.model.*
import hudson.model.*

println Jenkins.instance.clouds

for (x in Jenkins.instance.clouds) {

  println x
  println x.templates

  for (t in x.templates) {
    println t
    println t.launcher
  }

}
