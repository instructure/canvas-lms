/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import renderBigBlueButtonAlert from 'jsx/conferences/renderBigBlueButtonAlert'

QUnit.module('Conferences > .renderBigBlueButtonAlert()', () => {
  test('renders the alert into the container', () => {
    const $container = document.body.appendChild(document.createElement('div'))
    $container.id = 'big-blue-button-message-container'
    renderBigBlueButtonAlert()
    strictEqual($container.children.length, 1)
  })
})
