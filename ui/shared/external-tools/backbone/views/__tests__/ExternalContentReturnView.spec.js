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

import 'jquery-migrate'
import fakeENV from '@canvas/test-utils/fakeENV'
import ExternalContentReturnView from '../ExternalContentReturnView'
import ExternalTool from '../../models/ExternalTool'

let view
let el
let iframe
let info

describe('ExternalContentReturnView screenreader only content', () => {
  beforeEach(() => {
    fakeENV.setup({
      context_asset_string: 'courses_1',
      LTI_LAUNCH_FRAME_ALLOWANCES: ['midi', 'media'],
    })
    view = new ExternalContentReturnView({model: new ExternalTool()})
    view.render()
    el = view.$el
    iframe = el.find('iframe')
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  test('shows beginning info alert and adds class to iframe', () => {
    info = el.find('.before_external_content_info_alert')
    info.focus()
    expect(info.hasClass('screenreader-only')).toBe(false)
    expect(iframe.hasClass('info_alert_outline')).toBe(true)
  })

  test('shows ending info alert and adds class to iframe', () => {
    info = el.find('.after_external_content_info_alert')
    info.focus()
    expect(info.hasClass('screenreader-only')).toBe(false)
    expect(iframe.hasClass('info_alert_outline')).toBe(true)
  })

  test('hides beginning info alert and removes class from iframe', () => {
    info = el.find('.before_external_content_info_alert')
    info.focus()
    info.blur()
    expect(info.hasClass('screenreader-only')).toBe(true)
    expect(iframe.hasClass('info_alert_outline')).toBe(false)
  })

  test('hides ending info alert and removes class from iframe', () => {
    info = el.find('.after_external_content_info_alert')
    info.focus()
    info.blur()
    expect(info.hasClass('screenreader-only')).toBe(true)
    expect(iframe.hasClass('info_alert_outline')).toBe(false)
  })

  test("doesn't show infos or add border to iframe by default", () => {
    expect(
      el.find(
        '.before_external_content_info_alert.screenreader-only, .after_external_content_info_alert.screenreader-only'
      ).length
    ).toBe(2)
    expect(iframe.hasClass('info_alert_outline')).toBe(false)
  })

  test("sets the proper values for the iframe 'allow' attribute", () => {
    expect(iframe.attr('allow')).toBe(ENV.LTI_LAUNCH_FRAME_ALLOWANCES.join('; '))
  })

  test("sets the proper values for the iframe 'data-lti-launch' attribute", () => {
    expect(iframe.attr('data-lti-launch')).toBe('true')
  })
})
