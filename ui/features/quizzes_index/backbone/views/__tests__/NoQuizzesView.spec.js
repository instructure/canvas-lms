/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import NoQuizzesView from '../NoQuizzesView'
import assertions from '@canvas/test-utils/assertionsSpec'
import '@canvas/jquery/jquery.simulate'

describe('NoQuizzesView', () => {
  let view

  beforeEach(() => {
    view = new NoQuizzesView()
  })

  test('it renders', () => {
    expect(view.$el.hasClass('item-group-condensed')).toBe(true)
  })
})
