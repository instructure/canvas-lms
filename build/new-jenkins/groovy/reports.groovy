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

def stashSpecCoverage(index) {
  dir("tmp") {
    stash name: "spec_coverage_${index}", includes: 'spec_coverage/**/*'
  }
}

def publishSpecCoverageToS3(ci_node_total, coverage_type) {
  sh 'rm -rf ./coverage_nodes'
  dir('coverage_nodes') {
    for(int index = 0; index < ci_node_total; index++) {
      dir("node_${index}") {
        unstash "spec_coverage_${index}"
      }
    }
  }

  sh './build/new-jenkins/rspec-coverage-report.sh'

  archiveArtifacts(artifacts: 'coverage_nodes/**')
  archiveArtifacts(artifacts: 'coverage/**')
  uploadCoverage([
      uploadSource: "/coverage",
      uploadDest: "$coverage_type/coverage"
  ])
  sh 'rm -rf ./coverage_nodes'
  sh 'rm -rf ./coverage'
}

// this method is to ensure that the stashing is done in a way that
// is expected in publishSpecFailuresAsHTML
def stashSpecFailures(index) {
  dir("tmp") {
    stash name: "spec_failures_${index}", includes: 'spec_failures/**/*', allowEmpty: true
  }
}

def publishSpecFailuresAsHTML(ci_node_total) {
  sh 'rm -rf ./compiled_failures'

  dir('compiled_failures') {
    for(int index = 0; index < ci_node_total; index++) {
      dir ("node_${index}") {
        try {
          unstash "spec_failures_${index}"
        } catch(err) {
          println (err)
        }

      }
    }
    buildIndexPage();
    htmlFiles = findFiles glob: '**/index.html'
  }

  publishHTML target: [
    allowMissing: false,
    alwaysLinkToLastBuild: false,
    keepAll: true,
    reportDir: 'compiled_failures',
    reportFiles: htmlFiles.join(','),
    reportName: 'Test Failures'
  ]
  sh 'rm -rf ./compiled_failures'
}

def buildIndexPage() {
  def indexHtml = "<body style=\"font-family:sans-serif;line-height:1.25;font-size:14px\">"
  def htmlFiles;
  htmlFiles = findFiles glob: '**/index.html'
  if (htmlFiles.size()<1) {
    indexHtml += "\\o/ yay good job, no failures"
  } else {
      Map<String, List<String>> failureCategory = [:]
      htmlFiles.each { file ->
        def category = file.getPath().split("/")[2]
        if (failureCategory.containsKey("${category}")) {
          failureCategory.get("${category}").add("${file}")
        } else {
          failureCategory.put("${category}", [])
          failureCategory.get("${category}").add("${file}")
        }
      }
      failureCategory.each {category, failures ->
        indexHtml += "<h1>${category} Failures</h1>"
        failures.each { failure ->
          def spec = (failure =~ /.*spec_failures\/(.*)\/index/)[0][1]
          indexHtml += "<a href=\"${failure}\">${spec}</a><br>"
        }
      }
  }
  indexHtml += "</body>"
  writeFile file: "index.html", text: indexHtml
}

def snykCheckDependencies(projectImage, projectDirectory) {
  def projectContainer = sh(script: "docker run -d -it -v snyk_volume:${projectDirectory} ${projectImage}", returnStdout: true).trim()
  _runSnyk(
    projectContainer,
    projectDirectory,
    'canvas-lms:ruby',
    'snyk/snyk-cli:rubygems',
    'Gemfile.lock',
    './snyk_ruby'
  )
  archiveArtifacts(artifacts: '**/snyk*')
  sh 'rm -r ./snyk_ruby'
}

def _runSnyk(projectContainer, projectDirectory, projectName, snykImage, packageManagerFile, extractedReportsDirectory) {
  def credentials = load 'build/new-jenkins/groovy/credentials.groovy'
  credentials.withSnykCredentials({ ->
    def RC = sh(
      script: """
        set -o errexit -o nounset -o xtrace
        docker run --rm \
          -v snyk_volume:/project \
          -eSNYK_TOKEN \
          -e"MONITOR=true" \
           ${snykImage} test \
          --project-name=${projectName} \
          --file=${packageManagerFile}
      """, returnStatus: true
    )
    // Snyk returns a 1 if vulnerabilities are found; we don't want this to fail the build
    // If the return code is not 0 or 1, it's a build error and should throw an exception
    if(RC != 0 && RC != 1) {
      error "Snyk dependency check for ${projectName} failed with an unrecognized return code: $RC"
    }
  })
  this._extractSnykReports(projectContainer, projectDirectory, extractedReportsDirectory)
}

def _extractSnykReports(projectContainer, projectDirectory, destinationDirectory) {
  sh """
    set -o errexit -o nounset -o xtrace
    mkdir -vp ${destinationDirectory}
    docker cp ${projectContainer}:${projectDirectory}/snyk-error.log ${destinationDirectory}/snyk-error.log
    docker cp ${projectContainer}:${projectDirectory}/snyk-result.json ${destinationDirectory}/snyk-result.json
    docker cp ${projectContainer}:${projectDirectory}/snyk_report.css ${destinationDirectory}/snyk_report.css
    docker cp ${projectContainer}:${projectDirectory}/snyk_report.html ${destinationDirectory}/snyk_report.html
  """
}

return this
