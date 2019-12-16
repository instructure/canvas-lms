/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

// this method is to ensure that the stashing is done in a way that
// is expected in publishSpecFailuresAsHTML
def stashSpecFailures(index) {
  stash name: "spec_failures_${index}", includes: 'spec_failures/**/*', allowEmpty: true
}

def publishSpecFailuresAsHTML(ci_node_total) {
  sh 'rm -rf ./compiled_failures'
  def htmlFiles;
  dir('compiled_failures') {
    for(int i = 0; i < ci_node_total; i++) {
      def index = i;
      dir ("node_${index}") {
        unstash "spec_failures_${index}"
      }
    }
    htmlFiles = findFiles glob: '**/index.html'

    def indexHtml = "<body style=\"font-family:sans-serif;line-height:1.25;font-size:14px\">"
    htmlFiles.each {
      def spec = (it =~ /.*spec_failures\/(.*)\/index/)[0][1]
      indexHtml += "<a href=\"${it}\">${spec}</a><br>"
    }
    indexHtml += "</body>"
    writeFile file: "index.html", text: indexHtml
  }

  publishHTML target: [
    allowMissing: false,
    alwaysLinkToLastBuild: false,
    keepAll: true,
    reportDir: 'compiled_failures',
    reportFiles: "index.html," + htmlFiles.join(','),
    reportName: 'Test Failures'
  ]
  sh 'rm -rf ./compiled_failures'
}

return this
