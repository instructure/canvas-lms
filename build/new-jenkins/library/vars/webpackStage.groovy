/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

def calcBundleSizes() {
  sh '''
    docker run --name webpack-linters \
    $PATCHSET_TAG bash -c "./build/new-jenkins/record-webpack-sizes.sh"
   '''

   sh 'docker cp webpack-linters:/tmp/big_bundles.csv tmp/big_bundles.csv'

   def bigFileList = []
   def thingsWeKnowAreWayTooBig = [
     'account_settings',
     'assignment_edit',
     'assignment_index',
     'calendar',
     'discussion_topic_edit',
     'discussion_topics_post',
     'edit_rubric',
     'manage_groups',
     'wiki_page_show'
   ]

   def csv = readCSV file: 'tmp/big_bundles.csv'
   for (def records : csv) {

     // skip auto-generated bundles
     if (records[0] =~ /^\d/) {
      continue
     }

     reportToSplunk('webpack_bundle_size', [
       'fileName': records[0],
       'fileSize': records[1],
       'version': '3a',
     ])

     int fileSize = records[1].toInteger()
     // should match maxAssetSize value in ~/ui-build/webpack/index.js
     if ((fileSize > 1400000) && !thingsWeKnowAreWayTooBig.any{records[0].contains(it)}) {
       bigFileList.push(records[0])
     }
   }

   if (!bigFileList.isEmpty()) {
     def authorSlackId = env.GERRIT_EVENT_ACCOUNT_EMAIL ? slackUserIdFromEmail(email: env.GERRIT_EVENT_ACCOUNT_EMAIL, botUser: true, tokenCredentialId: 'slack-user-id-lookup') : ''
     def authorSlackMsg = authorSlackId ? "<@$authorSlackId>" : env.GERRIT_EVENT_ACCOUNT_NAME
     def authorSegment = "Patchset <${env.GERRIT_CHANGE_URL}|#${env.GERRIT_CHANGE_NUMBER}> by ${authorSlackMsg} includes an asset bundle over the recommended max size"
     def bigFiles = bigFileList.join(", ")
     def extra = "Bundle ${bigFiles} is too big and not in our known list of oversized bundles. This patchset may have pushed in over the acceptable limit. Please review the <https://inst.splunkcloud.com/en-US/app/search/report?sid=scheduler_cm9iZXJ0LmJ1dGVuQGluc3RydWN0dXJlLmNvbQ__search__RMD5ca61b6204ef60fe9_at_1650416400_45040_1987C8A1-0299-4A02-A75B-503AB27123E0&s=%2FservicesNS%2Fnobody%2Fsearch%2Fsaved%2Fsearches%2Fwebpack_bundle_size|Webpack Bundle Size> to see how bundles have grown over time."
     def summaryUrl = "${env.BUILD_URL}/build-summary-report"

     slackSend(
       channel: '#canvas_builds',
       color: 'warning',
       message: "${authorSegment}. Build <${summaryUrl}|#${env.BUILD_NUMBER}>\n\n$extra"
     )
   }
}
