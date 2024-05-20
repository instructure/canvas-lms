//
// Copyright (C) 2018 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.
//

import $ from 'jquery'
import 'jquery-migrate'
import TokenInput from 'ui/features/roster/jquery/TokenInput'

test('allows the browse link to receive focus', () => {
  const $top = $('<div><div /></div>')
  const $node = $top.children()
  const options = {
    selector: {
      browser: 'mock',
    },
  }
  new TokenInput($node, options)
  const $browseLink = $top.find('a')
  equal($browseLink.length, 1)
  equal($browseLink.attr('href'), '#')
})
