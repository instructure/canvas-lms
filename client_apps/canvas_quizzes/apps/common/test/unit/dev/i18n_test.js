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
  var I18n = require('i18n!something')
  describe('I18n.t', function() {
    it('should work with a simple string for a default value', function() {
      expect(I18n.t('Foo')).toEqual('Foo')
    })

    it('should work with a default object and an options object', function() {
      expect(I18n.t({one: '1 person', other: '%{count} people'}, {count: 2})).toBe('2 people')
    })

    it('should work with two params', function() {
      expect(I18n.t('foo', 'Foo')).toBe('Foo')
    })

    it('should interpolate options', function() {
      expect(
        I18n.t('foo', 'Hello %{some_var}', {
          some_var: 'World!'
        })
      ).toBe('Hello World!')
    })

    it('should use .zero when count is 0', function() {
      expect(
        I18n.t(
          'student_count',
          {
            zero: 'Nobody'
          },
          {count: 0}
        )
      ).toBe('Nobody')
    })

    it('should use .one when count is 1', function() {
      expect(
        I18n.t(
          'student_count',
          {
            zero: 'Nobody',
            one: 'One student'
          },
          {count: 1}
        )
      ).toBe('One student')
    })

    it('should use .other when count is greater than 1', function() {
      expect(
        I18n.t(
          'student_count',
          {
            zero: 'Nobody',
            one: 'One student',
            other: '%{count} students'
          },
          {count: 3}
        )
      ).toBe('3 students')
    })

    it('should just use the defaultValue', function() {
      expect(
        I18n.t('student_count', '%{count} students', {
          count: 3
        })
      ).toBe('3 students')
    })
  })
})
