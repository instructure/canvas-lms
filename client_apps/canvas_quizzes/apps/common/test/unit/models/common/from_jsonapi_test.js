/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

define(function(require) {
  var subject = require('canvas_quizzes/models/common/from_jsonapi')
  describe('Models.Common.fromJSONAPI', function() {
    it('should extract a set', function() {
      var output = subject(
        {
          quiz_reports: [
            {
              id: '1'
            }
          ]
        },
        'quiz_reports'
      )

      expect(Array.isArray(output)).toBe(true)
      expect(output[0].id).toBe('1')
    })

    it('should extract a set from a flat payload', function() {
      var output = subject(
        [
          {
            id: '1'
          }
        ],
        'quiz_reports'
      )

      expect(Array.isArray(output)).toBe(true)
      expect(output[0].id).toBe('1')
    })

    it('should extract a single object', function() {
      var output = subject(
        {
          quiz_reports: [
            {
              id: '1'
            }
          ]
        },
        'quiz_reports',
        true
      )

      expect(Array.isArray(output)).toBe(false)
      expect(output.id).toBe('1')
    })

    it('should extract a single object from a flat array payload', function() {
      var output = subject(
        [
          {
            id: '1'
          }
        ],
        'quiz_reports',
        true
      )

      expect(Array.isArray(output)).toBe(false)
      expect(output.id).toBe('1')
    })

    it('should extract a single object from a flat object payload', function() {
      var output = subject(
        {
          id: '1'
        },
        'quiz_reports',
        true
      )

      expect(Array.isArray(output)).toBe(false)
      expect(output.id).toBe('1')
    })
  })
})
