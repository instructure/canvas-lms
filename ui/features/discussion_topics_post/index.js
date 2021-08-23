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

import renderCanvasDiscussionPosts from './react/index'
import ready from '@instructure/ready'
import $ from 'jquery'

ready(() => {
  renderCanvasDiscussionPosts(ENV, $('<div/>').appendTo('#content')[0])
})
if (ENV.SEQUENCE != null) {
  import('@canvas/module-sequence-footer').then(() => {
    $(() => {
      $('<div id="module_sequence_footer" style="margin-top: 30px" />')
        .appendTo('#content')
        .moduleSequenceFooter({
          assetType: 'Discussion',
          assetID: ENV.SEQUENCE.ASSET_ID,
          courseID: ENV.SEQUENCE.COURSE_ID
        })
    })
  })
}
