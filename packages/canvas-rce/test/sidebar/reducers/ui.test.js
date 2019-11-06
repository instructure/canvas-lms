/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import assert from 'assert'
import ui from '../../../src/sidebar/reducers/ui'
import * as actions from '../../../src/sidebar/actions/ui'

describe('UI reducer', () => {
  describe('hidden flag', () => {
    it('is cleared on showSidebar', () => {
      const state = {hidden: true}
      const newState = ui(state, actions.showSidebar())
      assert.equal(newState.hidden, false)
    })

    it('is cleared on resetUI', () => {
      const state = {hidden: true}
      const newState = ui(state, actions.resetUI())
      assert.equal(newState.hidden, false)
    })

    it('is set on hideSidebar', () => {
      const state = {hidden: false}
      const newState = ui(state, actions.hideSidebar())
      assert.equal(newState.hidden, true)
    })
  })
})
