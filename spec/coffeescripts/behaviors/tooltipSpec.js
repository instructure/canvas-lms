/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import tooltip from 'compiled/behaviors/tooltip'

QUnit.module('tooltip position selection', {
  setup() {},
  teardown() {}
})

test('provides a position hash for a cardinal direction', () => {
  const opts = {position: 'bottom'}
  tooltip.setPosition(opts)
  const expected = {
    my: 'center top',
    at: 'center bottom+5',
    collision: 'flipfit'
  }
  equal(opts.position.my, expected.my)
  equal(opts.position.at, expected.at)
  equal(opts.position.collision, expected.collision)
})

test('can be compelled to abandon collision detection', () => {
  const opts = {
    position: 'bottom',
    force_position: 'true'
  }
  tooltip.setPosition(opts)
  equal(opts.position.collision, 'none')
})
