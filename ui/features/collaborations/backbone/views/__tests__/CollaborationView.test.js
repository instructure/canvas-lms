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
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import 'jquery-migrate'
import fakeENV from '@canvas/test-utils/fakeENV'
import CollaborationView from '../CollaborationView'

describe('CollaborationsView screenreader only content', () => {
  let fixtures
  let view

  beforeEach(() => {
    fixtures = document.createElement('div')
    fixtures.id = 'fixtures'
    document.body.appendChild(fixtures)

    fixtures.innerHTML = `
      <div class="container" data-id="15" data-testid="collaboration-container">
        <a class="edit_collaboration_link" href=""></a>
        <iframe data-testid="collaboration-iframe"></iframe>
      </div>
    `
    view = new CollaborationView({el: fixtures.querySelector('.container')})
    view.render()
    fakeENV.setup({LTI_LAUNCH_FRAME_ALLOWANCES: ['midi', 'media']})
  })

  afterEach(() => {
    fakeENV.teardown()
    fixtures.remove()
  })

  it('set iframe allowances', () => {
    const iframeTemplate = view.iframeTemplate('about:blank')
    expect($(iframeTemplate[0]).attr('allow')).toBe(ENV.LTI_LAUNCH_FRAME_ALLOWANCES.join('; '))
  })
})
