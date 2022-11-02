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
  }
}
