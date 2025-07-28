/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {prepareItemData} from '../editItemHandlers'

describe('editItemHandlers', () => {
  describe('prepareItemData', () => {
    it('should prepare item data', () => {
      const itemData = {
        title: 'Testing',
        indentation: 3,
      }
      const result = prepareItemData(itemData)
      expect(result).toEqual({
        'content_tag[title]': 'Testing',
        'content_tag[indent]': 3,
        new_tab: 0,
        graded: 0,
        _method: 'PUT',
      })
    })

    it('handles empty title', () => {
      const inputData = {
        title: '',
        indentation: 0,
      }

      const result = prepareItemData(inputData)

      expect(result).toEqual({
        'content_tag[title]': '',
        'content_tag[indent]': 0,
        new_tab: 0,
        graded: 0,
        _method: 'PUT',
      })
    })
  })
})
