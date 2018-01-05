/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import fakeENV from 'helpers/fakeENV'
import CollaborationView from 'compiled/views/collaborations/CollaborationView'

let fixtures
let view
let el
let iframe
let info

QUnit.module('CollaborationsView screenreader only content', {
  setup () {
    fixtures = $('#fixtures')
    fixtures.append(`
      <div class="container" data-id="15">
        <a class="edit_collaboration_link" href=""></a>
        <div class="before_external_content_info_alert screenreader-only" tabindex="0">
          <div class="ic-flash-info">
            <div class="ic-flash__icon" aria-hidden="true">
              <i class="icon-info"></i>
            </div>
            The following content is partner provided
          </div>
        </div>
        <iframe></iframe>
        <div class="after_external_content_info_alert screenreader-only" tabindex="0">
          <div class="ic-flash-info">
            <div class="ic-flash__icon" aria-hidden="true">
              <i class="icon-info"></i>
            </div>
            The preceding content is partner provided
          </div>
        </div>
      </div>
    `)
    view = new CollaborationView({ el: fixtures.find('.container') })
    view.render()
    el = view.$el
    iframe = el.find('iframe')
    fakeENV.setup({LTI_LAUNCH_FRAME_ALLOWANCES: ['midi', 'media']})
  },

  teardown () {
    fakeENV.teardown()
    fixtures.empty()
  }
})

test('shows beginning info alert and adds class to iframe', () => {
  info = el.find('.before_external_content_info_alert')
  info.focus()
  notOk(info.hasClass('screenreader-only'))
  ok(iframe.hasClass('info_alert_outline'))
})

test('shows ending info alert and adds class to iframe', () => {
  info = el.find('.after_external_content_info_alert')
  info.focus()
  notOk(info.hasClass('screenreader-only'))
  ok(iframe.hasClass('info_alert_outline'))
})

test('hides beginning info alert and removes class from iframe', () => {
  info = el.find('.before_external_content_info_alert')
  info.focus()
  info.blur()
  ok(info.hasClass('screenreader-only'))
  notOk(iframe.hasClass('info_alert_outline'))
})

test('hides ending info alert and removes class from iframe', () => {
  info = el.find('.after_external_content_info_alert')
  info.focus()
  info.blur()
  ok(info.hasClass('screenreader-only'))
  notOk(iframe.hasClass('info_alert_outline'))
})

test("doesn't show infos or add border to iframe by default", () => {
  equal(el.find('.before_external_content_info_alert.screenreader-only, .after_external_content_info_alert.screenreader-only').length, 2)
  notOk(iframe.hasClass('info_alert_outline'))
})

test('testing stuff', () => {
  const iframeTemplate = view.iframeTemplate('about:blank')
  equal($(iframeTemplate[2]).attr('allow'), ENV.LTI_LAUNCH_FRAME_ALLOWANCES.join('; '))
})
