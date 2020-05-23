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

def upload(events) {
  def data = events.collect { new JsonBuilder(it).toString() }.join('')
  load('build/new-jenkins/groovy/credentials.groovy').withSplunkCredentials({
    sh "build/new-jenkins/splunk_event.sh '$data'"
  })
}

def event(name, fields) {
  return [
    "sourcetype": "jenkins",
    "event": name,
    "fields": fields
  ]
}

def uploadEvent(name, fields) {
  upload([event(name, fields)])
}

return this
