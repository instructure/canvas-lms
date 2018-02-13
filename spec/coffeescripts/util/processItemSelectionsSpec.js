/*
 * Copyright (C) 2012 - present Instructure, Inc.
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

import processItemSelections from 'compiled/util/processItemSelections'

QUnit.module('processItemSelections')

test('move hash of selected items to list of selected', () => {
  const data = {
    authenticity_token: 'watup=',
    'copy[all_assignments]': '1',
    'copy[all_external_tools]': '1',
    'copy[all_files]': '1',
    'copy[assignment_group_552]': '1',
    'copy[attachment_6949]': '1',
    'copy[context_external_tool_253]': '1',
    'copy[context_external_tool_254]': '0',
    'copy[course_id]': '132',
    'copy[course_settings]': '1',
    'copy[day_substitutions][0]': '0',
    'copy[everything]': '0',
    'copy[folder_1564]': '1',
    'copy[new_end_date]': '',
    'copy[new_start_date]': '',
    'copy[old_end_date]': 'Fri Jan 27, 2012',
    'copy[old_start_date]': 'Fri Jan 20, 2012',
    'copy[shift_dates]': '1'
  }
  const newData = processItemSelections(data)
  deepEqual(newData, {
    items_to_copy: [
      'all_assignments',
      'all_external_tools',
      'all_files',
      'assignment_group_552',
      'attachment_6949',
      'context_external_tool_253',
      'course_settings',
      'folder_1564',
      'shift_dates'
    ],
    authenticity_token: 'watup=',
    'copy[course_id]': '132',
    'copy[day_substitutions][0]': '0',
    'copy[new_end_date]': '',
    'copy[new_start_date]': '',
    'copy[old_end_date]': 'Fri Jan 27, 2012',
    'copy[old_start_date]': 'Fri Jan 20, 2012'
  })
})
