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

import $ from 'jquery'

export default function setDefaultToolValues(
  result: {url: string},
  tool: {
    definition_type: string
    definition_id: string
  }
) {
  $('#assignment_external_tool_tag_attributes_content_type').val(tool.definition_type)
  $('#assignment_external_tool_tag_attributes_content_id').val(tool.definition_id)
  $('#assignment_external_tool_tag_attributes_url').val(result.url)
  $('#assignment_external_tool_tag_attributes_iframe_width').val('')
  $('#assignment_external_tool_tag_attributes_iframe_height').val('')

  window.postMessage(
    {
      subject: 'defaultToolContentReady',
      content: result,
    },
    ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN
  )
}
