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

import Handlebars from '..'
import $ from 'jquery'
import 'jquery-migrate'
import _ from 'lodash'
import fakeENV from '@canvas/test-utils/fakeENV'
import tzInTest from '@instructure/moment-utils/specHelpers'
import timezone from 'timezone'
import detroit from 'timezone/America/Detroit'
import chicago from 'timezone/America/Chicago'
import I18n from 'i18n-js'
import {getI18nFormats} from '@canvas/datetime/configureDateTime'

const {helpers} = Handlebars

describe('handlebars_helpers', () => {
  describe('checkbox', () => {
    const context = {
      likes: {
        tacos: true,
      },
      human: true,
      alien: false,
    }

    const testCheckbox = (context, prop, hash = {}) => {
      const $input = $(`<span>${helpers.checkbox.call(context, prop, {hash}).string}</span>`)
        .find('input')
        .eq(1)

      const checks = _.defaults(hash, {
        value: 1,
        tagName: 'INPUT',
        type: 'checkbox',
        name: prop,
        checked: context[prop],
        id: prop,
      })

      Object.entries(checks).forEach(([key, val]) => {
        if (key === 'value') {
          expect($input.prop(key).toString()).toBe(val.toString())
        } else {
          expect($input.prop(key)).toBe(val)
        }
      })
    }

    it('handles simple case', () => {
      testCheckbox(context, 'human')
    })

    it('handles custom hash attributes', () => {
      const hash = {
        class: 'foo bar baz',
        id: 'custom_id',
      }
      testCheckbox(context, 'human', hash)
    })

    it('handles nested property', () => {
      testCheckbox(context, 'likes.tacos', {
        id: 'likes_tacos',
        name: 'likes[tacos]',
        checked: context.likes.tacos,
      })
    })

    it('handles hidden input values', () => {
      const hiddenInput = ({disabled}) => {
        const inputs = helpers.checkbox.call(context, 'blah', {hash: {disabled}})
        const div = $(`<div>${inputs}</div>`)
        return div.find('[type=hidden]')
      }

      expect(hiddenInput({disabled: false}).prop('disabled')).toBeFalsy()
      expect(hiddenInput({disabled: true}).prop('disabled')).toBeTruthy()
    })
  })

  it('titleize formats strings correctly', () => {
    expect(helpers.titleize('test_string')).toBe('Test String')
    expect(helpers.titleize(null)).toBe('')
    expect(helpers.titleize('test_ _string')).toBe('Test String')
  })

  it('toPrecision formats numbers correctly', () => {
    expect(helpers.toPrecision(3.6666666, 2)).toBe('3.7')
  })

  describe('truncate', () => {
    it('default truncates 30 characters', () => {
      const text = 'asdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdf'
      const truncText = helpers.truncate(text)
      expect(truncText).toHaveLength(30)
    })

    it('expects options for max length', () => {
      const text = 'asdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdf'
      const truncText = helpers.truncate(text, 10)
      expect(truncText).toHaveLength(10)
    })

    it('supports truncation left', () => {
      const text = 'going to the store'
      const truncText = helpers.truncate_left(text, 15)
      expect(truncText).toBe('...to the store')
    })
  })

  describe('friendlyDatetime', () => {
    beforeEach(() => {
      tzInTest.configureAndRestoreLater({
        tz: timezone(detroit, 'America/Detroit'),
        tzData: {
          'America/Detroit': detroit,
        },
        formats: getI18nFormats(),
      })
    })

    afterEach(() => {
      tzInTest.restore()
    })

    it('can take an ISO string', () => {
      const result = helpers.friendlyDatetime('1970-01-01 00:00:00Z', {
        hash: {pubDate: false},
      }).string
      expect(result).toContain('Dec 31, 1969 at 7pm')
    })

    it('can take a date object', () => {
      const result = helpers.friendlyDatetime(new Date(0), {hash: {pubDate: false}}).string
      expect(result).toContain('Dec 31, 1969 at 7pm')
    })

    it('should parse non-qualified string relative to profile timezone', () => {
      const result = helpers.friendlyDatetime('1970-01-01 00:00:00', {
        hash: {pubDate: false},
      }).string
      expect(result).toContain('Jan 1, 1970 at 12am')
    })

    it('includes a screenreader accessible version', () => {
      const result = helpers.friendlyDatetime(new Date(0), {hash: {pubDate: false}}).string
      expect(result).toContain('<span class="screenreader-only">Dec 31, 1969 at 7pm</span>')
    })

    it('includes a visible version', () => {
      const result = helpers.friendlyDatetime(new Date(0), {hash: {pubDate: false}}).string
      expect(result).toContain('<span aria-hidden="true">Dec 31, 1969</span>')
    })
  })

  describe('contextSensitive FriendlyDatetime', () => {
    beforeEach(() => {
      fakeENV.setup()
      ENV.CONTEXT_TIMEZONE = 'America/Chicago'
      tzInTest.configureAndRestoreLater({
        tz: timezone(detroit, 'America/Detroit'),
        tzData: {
          'America/Chicago': chicago,
          'America/Detroit': detroit,
        },
        formats: getI18nFormats(),
      })
    })

    afterEach(() => {
      fakeENV.teardown()
      tzInTest.restore()
    })

    it('displays both zones data from an ISO string', () => {
      const timeTag = helpers.friendlyDatetime('1970-01-01 00:00:00Z', {
        hash: {pubDate: false, contextSensitive: true},
      }).string
      expect(timeTag).toContain('Local: Dec 31, 1969 at 7pm')
    })

    it('just passes through to datetime string if there is no contextual timezone', () => {
      ENV.CONTEXT_TIMEZONE = null
      const result = helpers.contextSensitiveDatetimeTitle('1970-01-01 00:00:00Z', {hash: {}})
      expect(result).toBeDefined()
    })
  })

  describe('ifSettingIs', () => {
    it('calls the fn if the setting matches the value', () => {
      ENV.SETTINGS = {key: 'value'}
      let semaphore = false
      const funcs = {
        fn: () => {
          semaphore = true
        },
        inverse: () => {
          semaphore = false
        },
        hash: {},
      }
      helpers.ifSettingIs('key', 'value', funcs)
      expect(semaphore).toBe(true)
    })
  })

  describe('number helpers', () => {
    beforeEach(() => {
      I18n.locale = 'en'
    })

    it('proxies to I18n.localizeNumber', () => {
      const num = 47
      const precision = 2
      const result = helpers.n(num, {hash: {precision}})
      expect(result).toBeDefined()
    })

    it('proxies to numberFormat', () => {
      const num = 2.34
      const format = 'outcomeScore'
      const result = helpers.nf(num, {hash: {format}})
      expect(result).toBeDefined()
    })
  })

  describe('selectedIfNumber helper', () => {
    it('returns selected if the number is equal to the value', () => {
      const result = helpers.selectedIfNumber(1, 1)
      expect(result).toBe('selected')
    })

    it('returns empty string if the number is not equal to the value', () => {
      const result = helpers.selectedIfNumber(1, 2)
      expect(result).toBe('')
    })

    it('returns selected if one of the params is a string number', () => {
      const result = helpers.selectedIfNumber('1', 1)
      expect(result).toBe('selected')
    })
  })
})
