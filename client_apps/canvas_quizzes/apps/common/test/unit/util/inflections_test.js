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
  var Inflections = require('util/inflections')

  describe('Inflections', function() {
    describe('#camelize', function() {
      var subject = Inflections.camelize

      it('foo to Foo', function() {
        expect(subject('foo')).toEqual('Foo')
      })

      it('foo_bar to FooBar (default)', function() {
        expect(subject('foo_bar')).toEqual('FooBar')
      })

      it('foo_bar to fooBar', function() {
        expect(subject('foo_bar', true)).toEqual('fooBar')
      })

      it('fooBar to fooBar', function() {
        expect(subject('fooBar', true)).toEqual('fooBar')
      })

      it('does not blow up with nulls or empty strings', function() {
        expect(function() {
          subject(undefined)
        }).not.toThrow()

        expect(function() {
          subject('')
        }).not.toThrow()
      })
    })
  })
})
