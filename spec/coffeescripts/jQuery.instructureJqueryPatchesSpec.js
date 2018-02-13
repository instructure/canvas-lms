/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import jQuery from 'jquery'
import 'jquery.instructure_jquery_patches'

QUnit.module('instructure jquery patches')

test('parseJSON', () => {
  deepEqual(
    jQuery.parseJSON('{ "var1": "1", "var2" : 2 }'),
    {
      var1: '1',
      var2: 2
    },
    'should still parse without the prefix'
  )
  deepEqual(
    jQuery.parseJSON('while(1);{ "var1": "1", "var2" : 2 }'),
    {
      var1: '1',
      var2: 2
    },
    'should parse with the prefix'
  )
})
