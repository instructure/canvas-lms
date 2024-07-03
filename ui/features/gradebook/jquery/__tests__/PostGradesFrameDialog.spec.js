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
import PostGradesFrameDialog from '../PostGradesFrameDialog'

describe('Gradebook > PostGradesFrameDialog', () => {
  let dialog
  let el
  let iframe

  beforeEach(() => {
    fakeENV.setup({LTI_LAUNCH_FRAME_ALLOWANCES: ['midi', 'media']})
    dialog = new PostGradesFrameDialog({})
    dialog.open()
    el = dialog.$dialog
    iframe = el.find('iframe')
  })

  afterEach(() => {
    dialog.close()
    dialog.$dialog.remove()
    fakeENV.teardown()
  })

  describe('screenreader only content', () => {
    test('shows beginning info alert and adds class to iframe', () => {
      const info = el.find('.before_external_content_info_alert')
      info.focus()
      expect(info.children().hasClass('screenreader-only')).toBeFalsy()
      expect(iframe.hasClass('info_alert_outline')).toBeTruthy()
    })

    test('shows ending info alert and adds class to iframe', () => {
      const info = el.find('.after_external_content_info_alert')
      info.focus()
      expect(info.children().hasClass('screenreader-only')).toBeFalsy()
      expect(iframe.hasClass('info_alert_outline')).toBeTruthy()
    })

    test('hides beginning info alert and removes class from iframe', () => {
      const info = el.find('.before_external_content_info_alert')
      info.focus()
      info.blur()
      expect(info.children().hasClass('screenreader-only')).toBeTruthy()
      expect(iframe.hasClass('info_alert_outline')).toBeFalsy()
    })

    test('hides ending info alert and removes class from iframe', () => {
      const info = el.find('.after_external_content_info_alert')
      info.focus()
      info.blur()
      expect(info.children().hasClass('screenreader-only')).toBeTruthy()
      expect(iframe.hasClass('info_alert_outline')).toBeFalsy()
    })

    test("doesn't show infos or add border to iframe by default", () => {
      expect(
        el.find(
          '.before_external_content_info_alert > .screenreader-only, .after_external_content_info_alert > .screenreader-only'
        ).length
      ).toBe(2)
      expect(iframe.hasClass('info_alert_outline')).toBeFalsy()
    })

    test("sets the 'data-lti-launch' attribute on the iframe", () => {
      expect(iframe.attr('data-lti-launch')).toBe('true')
    })
  })
})
