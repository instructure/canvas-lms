/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import JQuery from 'jquery'

export function fetchContent($section: JQuery, section_type: string, name: string) {
  const data: Record<string, unknown> = {}
  if (section_type === 'rich_text') {
    data[name + '[section_type]'] = 'rich_text'
    const editorContent = $section.find('.section_content').html()
    if (editorContent) {
      data[name + '[content]'] = editorContent
    }
  } else if (section_type === 'html') {
    data[name + '[section_type]'] = 'html'
    data[name + '[content]'] = $section.find('.edit_section').val()
  } else if (section_type === 'submission') {
    data[name + '[section_type]'] = 'submission'
    data[name + '[submission_id]'] = $section.getTemplateData({
      textValues: ['submission_id'],
    }).submission_id
  } else if (section_type === 'attachment') {
    data[name + '[section_type]'] = 'attachment'
    data[name + '[attachment_id]'] = $section.getTemplateData({
      textValues: ['attachment_id'],
    }).attachment_id
  }
  return data
}
