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
  let el
  let iframe
  let info

  beforeEach(() => {
    fixtures = document.createElement('div')
    fixtures.id = 'fixtures'
    document.body.appendChild(fixtures)

    fixtures.innerHTML = `
      <div class="container" data-id="15" data-testid="collaboration-container">
        <a class="edit_collaboration_link" href=""></a>
        <div class="before_external_content_info_alert screenreader-only" tabindex="0" data-testid="before-info-alert">
          <div class="ic-flash-info">
            <div class="ic-flash__icon" aria-hidden="true">
              <i class="icon-info"></i>
            </div>
            The following content is partner provided
          </div>
        </div>
        <iframe data-testid="collaboration-iframe"></iframe>
        <div class="after_external_content_info_alert screenreader-only" tabindex="0" data-testid="after-info-alert">
          <div class="ic-flash-info">
            <div class="ic-flash__icon" aria-hidden="true">
              <i class="icon-info"></i>
            </div>
            The preceding content is partner provided
          </div>
        </div>
      </div>
    `
    view = new CollaborationView({el: fixtures.querySelector('.container')})
    view.render()
    el = view.$el
    iframe = el.find('iframe')
    fakeENV.setup({LTI_LAUNCH_FRAME_ALLOWANCES: ['midi', 'media']})
  })

  afterEach(() => {
    fakeENV.teardown()
    fixtures.remove()
  })

  it('shows beginning info alert and adds class to iframe', () => {
    info = el.find('.before_external_content_info_alert')
    info.focus()
    expect(info.hasClass('screenreader-only')).toBeFalsy()
    expect(iframe.hasClass('info_alert_outline')).toBeTruthy()
  })

  it('shows ending info alert and adds class to iframe', () => {
    info = el.find('.after_external_content_info_alert')
    info.focus()
    expect(info.hasClass('screenreader-only')).toBeFalsy()
    expect(iframe.hasClass('info_alert_outline')).toBeTruthy()
  })

  it('hides beginning info alert and removes class from iframe', () => {
    info = el.find('.before_external_content_info_alert')
    info.focus()
    info.blur()
    expect(info.hasClass('screenreader-only')).toBeTruthy()
    expect(iframe.hasClass('info_alert_outline')).toBeFalsy()
  })

  it('hides ending info alert and removes class from iframe', () => {
    info = el.find('.after_external_content_info_alert')
    info.focus()
    info.blur()
    expect(info.hasClass('screenreader-only')).toBeTruthy()
    expect(iframe.hasClass('info_alert_outline')).toBeFalsy()
  })

  it("doesn't show infos or add border to iframe by default", () => {
    expect(
      el.find(
        '.before_external_content_info_alert.screenreader-only, .after_external_content_info_alert.screenreader-only'
      )
    ).toHaveLength(2)
    expect(iframe.hasClass('info_alert_outline')).toBeFalsy()
  })

  it('testing stuff', () => {
    const iframeTemplate = view.iframeTemplate('about:blank')
    expect($(iframeTemplate[2]).attr('allow')).toBe(ENV.LTI_LAUNCH_FRAME_ALLOWANCES.join('; '))
  })
})
