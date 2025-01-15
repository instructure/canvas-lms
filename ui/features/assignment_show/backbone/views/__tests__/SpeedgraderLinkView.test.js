/*
 * Copyright (C) 2024 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for
 * more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import SpeedgraderLinkView from '../SpeedgraderLinkView'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import {cleanup} from '@testing-library/react'
import assertions from '@canvas/test-utils/assertionsSpec'

describe('SpeedgraderLinkView', () => {
  let model, container

  beforeEach(() => {
    model = new Assignment({published: false})
    container = document.createElement('div')
    container.id = 'fixtures'
    document.body.appendChild(container)
    container.innerHTML = `
      <ul>
        <li id="assignment-speedgrader-link" class="hidden"></li>
      </ul>
    `
    new SpeedgraderLinkView({
      model,
      el: document.querySelector('#assignment-speedgrader-link'),
    }).render()
  })

  afterEach(() => {
    cleanup()
    document.body.innerHTML = ''
  })

  it('should be accessible', async () => {
    const element = document.querySelector('#assignment-speedgrader-link')
    expect(element).not.toBeNull()
    await assertions.isAccessible(element, {a11yReport: true})
  })

  it('toggles visibility of speedgrader link on change', () => {
    const speedgraderLink = document.querySelector('#assignment-speedgrader-link')
    expect(speedgraderLink.classList.contains('hidden')).toBe(true)
    model.set('published', true)
    expect(speedgraderLink.classList.contains('hidden')).toBe(false)
    model.set('published', false)
    expect(speedgraderLink.classList.contains('hidden')).toBe(true)
  })
})
