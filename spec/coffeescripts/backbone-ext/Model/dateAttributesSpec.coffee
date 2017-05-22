#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define ['compiled/backbone-ext/Model'], (Model) ->

  QUnit.module 'dateAttributes'

  test 'converts date strings to date objects', ->

    class TestModel extends Model
      dateAttributes: ['foo', 'bar']

    stringDate = "2012-04-10T17:21:09-06:00"
    parsedDate = Date.parse stringDate

    res = TestModel::parse
      foo: stringDate
      bar: null
      baz: stringDate

    expected =
      foo: parsedDate
      bar: null
      baz: stringDate

    deepEqual res, expected
