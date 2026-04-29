/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {isGuidDataValid, getAbGuidArray} from '../DiscussionTopicForm'

describe('DiscussionTopicForm utility functions', () => {
  describe('validate abGuid for Mastery Connect', () => {
    it('returns the ab_guid array from the event data', () => {
      const mockEvent = {
        data: {
          subject: 'assignment.set_ab_guid',
          data: ['1E20776E-7053-11DF-8EBF-BE719DFF4B22', '1E20776E-7053-0000-0000-BE719DFF4B22'],
        },
      }

      expect(getAbGuidArray(mockEvent)).toEqual([
        '1E20776E-7053-11DF-8EBF-BE719DFF4B22',
        '1E20776E-7053-0000-0000-BE719DFF4B22',
      ])
    })

    it('isGuidDataValid returns true if ab_guid format and subject are correct', () => {
      const mockEvent = {
        data: {
          subject: 'assignment.set_ab_guid',
          data: ['1E20776E-7053-11DF-8EBF-BE719DFF4B22'],
        },
      }

      expect(isGuidDataValid(mockEvent)).toEqual(true)
    })

    it('isGuidDataValid returns false if subject is not assignment.set_ab_guid', () => {
      const mockEvent = {
        data: {
          subject: 'not right subject',
          data: ['1E20776E-7053-11DF-8EBF-BE719DFF4B22'],
        },
      }

      expect(isGuidDataValid(mockEvent)).toBe(false)
    })

    it('isGuidDataValid returns false if at least one of the ab_guids in the array is not formatted correctly', () => {
      const mockEvent = {
        data: {
          subject: 'assignment.set_ab_guid',
          data: ['not right format', '1E20776E-7053-11DF-8EBF-BE719DFF4B22'],
        },
      }

      expect(isGuidDataValid(mockEvent)).toBe(false)
    })
  })
})
