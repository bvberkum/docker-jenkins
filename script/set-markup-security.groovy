import jenkins.model.*
import hudson.security.*
import hudson.markup.RawHtmlMarkupFormatter
import hudson.markup.EscapedMarkupFormatter


def instance = Jenkins.getInstance()
def globalSecConf = new GlobalSecurityConfiguration()

// Set from default security to safe-HTML

def formatter = globalSecConf.getMarkupFormatter()
if (formatter in EscapedMarkupFormatter) {
  instance.setMarkupFormatter(RawHtmlMarkupFormatter.INSTANCE)
  instance.save()
}

