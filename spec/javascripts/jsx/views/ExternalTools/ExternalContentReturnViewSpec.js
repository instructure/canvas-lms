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

import fakeENV from 'helpers/fakeENV'
import ExternalContentReturnView from '@canvas/external-tools/backbone/views/ExternalContentReturnView'
import ExternalTool from '@canvas/external-tools/backbone/models/ExternalTool'

let view
let el
let iframe
let info

QUnit.module('ExternalContentReturnView screenreader only content', {
  setup() {
    fakeENV.setup({
      context_asset_string: 'courses_1',
      LTI_LAUNCH_FRAME_ALLOWANCES: ['midi', 'media'],
    })
    view = new ExternalContentReturnView({model: new ExternalTool()})
    view.render()
    el = view.$el
    iframe = el.find('iframe')
  },

  teardown() {
    fakeENV.teardown()
  },
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
  equal(
    el.find(
      '.before_external_content_info_alert.screenreader-only, .after_external_content_info_alert.screenreader-only'
    ).length,
    2
  )
  notOk(iframe.hasClass('info_alert_outline'))
})

test("sets the proper values for the iframe 'allow' attribute", () => {
  equal(iframe.attr('allow'), ENV.LTI_LAUNCH_FRAME_ALLOWANCES.join('; '))
})

test("sets the proper values for the iframe 'data-lti-launch' attribute", () => {
  equal(iframe.attr('data-lti-launch'), 'true')
})
