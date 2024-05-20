/* eslint-disable no-global-assign */
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
import 'jquery-migrate'
import fakeENV from 'helpers/fakeENV'
import CollaborationsPage from 'collaborations'

let fixtures
let el
let iframe

QUnit.module('CollaborationsPage screenreader only content', {
  setup() {
    fixtures = $('#fixtures')
    fixtures.append(`
      <div class="container" data-id="15">
        <div class="before_external_content_info_alert screenreader-only" tabindex="0">
          <div class="ic-flash-info">
            <div class="ic-flash__icon" aria-hidden="true">
              <i class="icon-info"></i>
            </div>
            The following content is partner provided
          </div>
        </div>
        <iframe id="lti_new_collaboration_iframe"></iframe>
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
    CollaborationsPage.Events.init()
    el = fixtures.find('.container')
    iframe = el.find('iframe')
  },

  teardown() {
    fakeENV.teardown()
    fixtures.empty()
  },
})

test('shows beginning info alert and adds class to iframe', () => {
  alert = el.find('.before_external_content_info_alert')
  alert.focus()
  notOk(alert.hasClass('screenreader-only'))
  ok(iframe.hasClass('info_alert_outline'))
})

test('shows ending info alert and adds class to iframe', () => {
  alert = el.find('.after_external_content_info_alert')
  alert.focus()
  notOk(alert.hasClass('screenreader-only'))
  ok(iframe.hasClass('info_alert_outline'))
})

test('hides beginning info alert and removes class from iframe', () => {
  alert = el.find('.before_external_content_info_alert')
  alert.focus()
  alert.blur()
  ok(alert.hasClass('screenreader-only'))
  notOk(iframe.hasClass('info_alert_outline'))
})

test('hides ending info alert and removes class from iframe', () => {
  alert = el.find('.after_external_content_info_alert')
  alert.focus()
  alert.blur()
  ok(alert.hasClass('screenreader-only'))
  notOk(iframe.hasClass('info_alert_outline'))
})

test("doesn't show alerts or add border to iframe by default", () => {
  equal(
    el.find(
      '.before_external_content_info_alert.screenreader-only, .after_external_content_info_alert.screenreader-only'
    ).length,
    2
  )
  notOk(iframe.hasClass('info_alert_outline'))
})
