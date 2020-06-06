/*
 * Copyright (C) 2020 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

// https://docs.splunk.com/Documentation/Splunk/8.0.3/Data/FormateventsforHTTPEventCollector#Event_metadata

import groovy.json.*

// Splunk can take one or more events:
// the json objects are simply concatenated if there are multiple (no [] and no commas)
def upload(events) {
  logEvents(events)
  load('build/new-jenkins/groovy/credentials.groovy').withSplunkCredentials({
    sh "build/new-jenkins/splunk_event.sh '${new JsonBuilder(events).toString()}'"
  })
}

def event(name, fields) {
  return [
    "sourcetype": "jenkins",
    "event": name,
    "fields": fields
  ]
}

// Rerun category is a string describing which rerun retry this test failure was
def eventForTestFailure(test, rerun_category) {
  return event('jenkins.test.failure', ['test': test, 'rerun_category': rerun_category])
}

def eventForBuildDuration(duration) {
  return event('jenkins.build.duration', ['duration': duration])
}

def eventForStageDuration(name, duration) {
  return event('jenkins.stage.duration', ['stage': name, 'duration': duration])
}

def eventForNodeWait(node, duration) {
  return event('jenkins.node.wait', ['node': node, 'duration': duration])
}

def logEvents(events) {
  def displaySize = 10
  def displayEventsString = new JsonBuilder(events.take(displaySize)).toPrettyString()
  println("Uploading ${events.size()} events to splunk (showing ${displaySize} events): ${displayEventsString}")
}

return this
