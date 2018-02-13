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

define ['compiled/arr/walk'], (walk) ->

  QUnit.module 'arr/walk'

  test 'walks a tree object', ->
    arr = [{name: 'a'}, {name: 'b'}]
    prop = 'none'
    str = ''
    walk arr, prop, (item) -> str += item.name
    equal str, 'ab', 'calls iterator with item'

    a = [{}]
    walk a, 'nuthin', (item, arr) ->
      equal arr, a, 'calls iterator with obj'

    a = [
      {a: [ #1
        {a: [ #2
          {a:[ #3
            {} #4
            {} #5
          ]}
          {a:[ #6
            {} #7
            {} #8
          ]}
        ]}
        {} #9
        {} #10
      ]}
      {
        a: [] # empty
      } #11
    ]

    c = 0
    walk a, 'a', -> c++
    equal c, 11

