/*
 * Copyright (C) 2012 - present Instructure, Inc.
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

import Handlebars from '@canvas/handlebars-helpers'
import $ from 'jquery'
import 'jquery-migrate'
import _ from 'lodash'
import assertions from 'helpers/assertions'
import fakeENV from 'helpers/fakeENV'
import numberFormat from '@canvas/i18n/numberFormat'
import tzInTest from '@canvas/datetime/specHelpers'
import timezone from 'timezone'
import detroit from 'timezone/America/Detroit'
import chicago from 'timezone/America/Chicago'
import newYork from 'timezone/America/New_York'
import I18n from 'i18n-js'
import {getI18nFormats} from 'ui/boot/initializers/configureDateTime'

const {helpers} = Handlebars
const {contains} = assertions

QUnit.module('handlebars_helpers')

QUnit.module('checkbox')

const context = {
  likes: {
    tacos: true,
  },
  human: true,
  alien: false,
}

// eslint-disable-next-line @typescript-eslint/no-shadow
const testCheckbox = function (context, prop, hash = {}) {
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

  return (() => {
    const result = []
    for (const key in checks) {
      const val = checks[key]
      result.push(equal($input.prop(key), val))
    }
    return result
  })()
}

test('simple case', () => testCheckbox(context, 'human'))

test('custom hash attributes', () => {
  const hash = {
    class: 'foo bar baz',
    id: 'custom_id',
  }
  return testCheckbox(context, 'human', hash, hash)
})

test('nested property', () =>
  testCheckbox(context, 'likes.tacos', {
    id: 'likes_tacos',
    name: 'likes[tacos]',
    checked: context.likes.tacos,
  }))

test('checkboxes - hidden input values', () => {
  const hiddenInput = function ({disabled}) {
    const inputs = helpers.checkbox.call(context, 'blah', {hash: {disabled}})
    const div = $(`<div>${inputs}</div>`)
    return div.find('[type=hidden]')
  }

  ok(!hiddenInput({disabled: false}).prop('disabled'))
  ok(hiddenInput({disabled: true}).prop('disabled'))
})

test('titleize', () => {
  equal(helpers.titleize('test_string'), 'Test String')
  equal(helpers.titleize(null), '')
  equal(helpers.titleize('test_ _string'), 'Test String')
})

test('toPrecision', () => equal(helpers.toPrecision(3.6666666, 2), '3.7'))

QUnit.module('truncate')

test('default truncates 30 characters', () => {
  const text = 'asdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdf'
  const truncText = helpers.truncate(text)
  equal(truncText.length, 30, 'Truncates down to 30 letters')
})

test('expects options for max (length)', () => {
  const text = 'asdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdf'
  const truncText = helpers.truncate(text, 10)
  equal(truncText.length, 10, 'Truncates down to 10 letters')
})

test('supports truncation left', () => {
  const text = 'going to the store'
  const truncText = helpers.truncate_left(text, 15)
  equal(truncText, '...to the store', 'Reverse truncates')
})

QUnit.module('friendlyDatetime', {
  setup() {
    tzInTest.configureAndRestoreLater({
      tz: timezone(detroit, 'America/Detroit'),
      tzData: {
        'America/Detroit': detroit,
      },
      formats: getI18nFormats(),
    })
  },

  teardown() {
    tzInTest.restore()
  },
})

test('can take an ISO string', () =>
  contains(
    helpers.friendlyDatetime('1970-01-01 00:00:00Z', {hash: {pubDate: false}}).string,
    'Dec 31, 1969 at 7pm'
  ))

test('can take a date object', () =>
  contains(
    helpers.friendlyDatetime(new Date(0), {hash: {pubDate: false}}).string,
    'Dec 31, 1969 at 7pm'
  ))

test('should parse non-qualified string relative to profile timezone', () =>
  contains(
    helpers.friendlyDatetime('1970-01-01 00:00:00', {hash: {pubDate: false}}).string,
    'Jan 1, 1970 at 12am'
  ))

test('includes a screenreader accessible version', () =>
  contains(
    helpers.friendlyDatetime(new Date(0), {hash: {pubDate: false}}).string,
    "<span class='screenreader-only'>Dec 31, 1969 at 7pm</span>"
  ))

test('includes a visible version', () =>
  contains(
    helpers.friendlyDatetime(new Date(0), {hash: {pubDate: false}}).string,
    "<span aria-hidden='true'>Dec 31, 1969</span>"
  ))

QUnit.module('contextSensitive FriendlyDatetime', {
  setup() {
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
  },

  teardown() {
    fakeENV.teardown()
    tzInTest.restore()
  },
})

test('displays both zones data from an ISO string', () => {
  const timeTag = helpers.friendlyDatetime('1970-01-01 00:00:00Z', {
    hash: {pubDate: false, contextSensitive: true},
  }).string
  contains(timeTag, 'Local: Dec 31, 1969 at 7pm')
  return contains(timeTag, 'Course: Dec 31, 1969 at 6pm')
})

test('displays both zones data from a date object', () => {
  const timeTag = helpers.friendlyDatetime(new Date(0), {
    hash: {pubDate: false, contextSensitive: true},
  }).string
  contains(timeTag, 'Local: Dec 31, 1969 at 7pm')
  return contains(timeTag, 'Course: Dec 31, 1969 at 6pm')
})

test('should parse non-qualified string relative to both timezones', () => {
  const timeTag = helpers.friendlyDatetime('1970-01-01 00:00:00', {
    hash: {pubDate: false, contextSensitive: true},
  }).string
  contains(timeTag, 'Local: Jan 1, 1970 at 12am')
  return contains(timeTag, 'Course: Dec 31, 1969 at 11pm')
})

test('reverts to friendly display when there is no contextual timezone', () => {
  ENV.CONTEXT_TIMEZONE = null
  const timeTag = helpers.friendlyDatetime('1970-01-01 00:00:00Z', {
    hash: {pubDate: false, contextSensitive: true},
  }).string
  return contains(timeTag, "<span aria-hidden='true'>Dec 31, 1969</span>")
})

QUnit.module('contextSensitiveDatetimeTitle', {
  setup() {
    fakeENV.setup()
    ENV.CONTEXT_TIMEZONE = 'America/Chicago'
    tzInTest.configureAndRestoreLater({
      tz: timezone(detroit, 'America/Detroit'),
      tzData: {
        'America/Chicago': chicago,
        'America/Detroit': detroit,
        'America/New_York': newYork,
      },
      formats: getI18nFormats(),
    })
  },

  teardown() {
    fakeENV.teardown()
    tzInTest.restore()
  },
})

test('just passes through to datetime string if there is no contextual timezone', () => {
  ENV.CONTEXT_TIMEZONE = null
  const titleText = helpers.contextSensitiveDatetimeTitle('1970-01-01 00:00:00Z', {
    hash: {justText: true},
  })
  equal(titleText, 'Dec 31, 1969 at 7pm')
})

test('splits title text to both zones', () => {
  const titleText = helpers.contextSensitiveDatetimeTitle('1970-01-01 00:00:00Z', {
    hash: {justText: true},
  })
  equal(titleText, 'Local: Dec 31, 1969 at 7pm<br>Course: Dec 31, 1969 at 6pm')
})

test('properly spans day boundaries', () => {
  ENV.TIMEZONE = 'America/Chicago'
  tzInTest.configureAndRestoreLater({
    tz: timezone(chicago, 'America/Chicago'),
    tzData: {
      'America/Chicago': chicago,
      'America/New_York': newYork,
    },
    formats: getI18nFormats(),
  })
  ENV.CONTEXT_TIMEZONE = 'America/New_York'
  const titleText = helpers.contextSensitiveDatetimeTitle('1970-01-01 05:30:00Z', {
    hash: {justText: true},
  })
  equal(titleText, 'Local: Dec 31, 1969 at 11:30pm<br>Course: Jan 1, 1970 at 12:30am')
})

test('stays as one title when the timezone is no different', () => {
  ENV.TIMEZONE = 'America/Detroit'
  ENV.CONTEXT_TIMEZONE = 'America/Detroit'
  const titleText = helpers.contextSensitiveDatetimeTitle('1970-01-01 00:00:00Z', {
    hash: {justText: true},
  })
  equal(titleText, 'Dec 31, 1969 at 7pm')
})

test('stays as one title when the time is no different even if timezone names differ', () => {
  ENV.TIMEZONE = 'America/Detroit'
  ENV.CONTEXT_TIMEZONE = 'America/New_York'
  const titleText = helpers.contextSensitiveDatetimeTitle('1970-01-01 00:00:00Z', {
    hash: {justText: true},
  })
  equal(titleText, 'Dec 31, 1969 at 7pm')
})

test('produces the html attributes if you dont specify just_text', () => {
  ENV.CONTEXT_TIMEZONE = null
  const titleText = helpers.contextSensitiveDatetimeTitle('1970-01-01 00:00:00Z', {
    hash: {justText: undefined},
  })
  equal(titleText, 'data-tooltip data-html-tooltip-title="Dec 31, 1969 at 7pm"')
})

QUnit.module('datetimeFormatted', {
  teardown() {
    tzInTest.restore()
  },
})

test('should parse and format relative to profile timezone', () => {
  tzInTest.configureAndRestoreLater({
    tz: timezone(detroit, 'America/Detroit'),
    tzData: {
      'America/Detroit': detroit,
    },
    formats: getI18nFormats(),
  })

  equal(helpers.datetimeFormatted('1970-01-01 00:00:00'), 'Jan 1, 1970 at 12am')
})

test('accepts formatting options', () => {
  tzInTest.configureAndRestoreLater({
    tz: timezone(detroit, 'America/Detroit'),
    tzData: {
      'America/Detroit': detroit,
    },
    formats: getI18nFormats(),
  })

  const now = new Date()
  const options = {format: 'medium'}
  const formattedDate = helpers.datetimeFormatted(now.toISOString(), {hash: options})
  ok(formattedDate.includes(now.getFullYear()))
})

QUnit.module('ifSettingIs')

test('it runs primary case if setting matches', () => {
  ENV.SETTINGS = {key: 'value'}
  let semaphore = false
  const funcs = {
    fn() {
      return (semaphore = true)
    },
    inverse() {
      throw new Error('Dont call this!')
    },
  }
  helpers.ifSettingIs('key', 'value', funcs)
  equal(semaphore, true)
})

test('it runs inverse case if setting does not match', () => {
  ENV.SETTINGS = {key: 'NOTvalue'}
  let semaphore = false
  const funcs = {
    inverse() {
      return (semaphore = true)
    },
    fn() {
      throw new Error('Dont call this!')
    },
  }
  helpers.ifSettingIs('key', 'value', funcs)
  equal(semaphore, true)
})

test('it runs inverse case if setting does not exist', () => {
  ENV.SETTINGS = {}
  let semaphore = false
  const funcs = {
    inverse() {
      return (semaphore = true)
    },
    fn() {
      throw new Error('Dont call this!')
    },
  }
  helpers.ifSettingIs('key', 'value', funcs)
  equal(semaphore, true)
})

QUnit.module('accessible date pickers')

test('it provides a format', () => equal(typeof helpers.accessibleDateFormat(), 'string'))

test('it can shorten the format for dateonly purposes', () => {
  const shortForm = helpers.accessibleDateFormat('date')
  equal(shortForm.indexOf('hh:mm'), -1)
  ok(shortForm.indexOf('YYYY') > -1)
})

test('it can shorten the format for time-only purposes', () => {
  const shortForm = helpers.accessibleDateFormat('time')
  ok(shortForm.indexOf('hh:mm') > -1)
  equal(shortForm.indexOf('YYYY'), -1)
})

test('it provides a common format prompt wrapped around the format', () => {
  const formatPrompt = helpers.datepickerScreenreaderPrompt()
  ok(formatPrompt.indexOf(helpers.accessibleDateFormat()) > -1)
})

test('it passes format info through to date format', () => {
  const shortFormatPrompt = helpers.datepickerScreenreaderPrompt('date')
  equal(shortFormatPrompt.indexOf(helpers.accessibleDateFormat()), -1)
  ok(shortFormatPrompt.indexOf(helpers.accessibleDateFormat('date')) > -1)
})

QUnit.module('i18n number helper', {
  setup() {
    this.ret = '47.00%'
    sandbox.stub(I18n, 'n').returns(this.ret)
  },
})

test('proxies to I18n.localizeNumber', function () {
  const num = 47
  const precision = 2
  const percentage = true
  equal(helpers.n(num, {hash: {precision, percentage}}), this.ret)
  ok(I18n.n.calledWithMatch(num, {precision, percentage}))
})

QUnit.module('i18n number format helper', {
  setup() {
    this.ret = '2,34'
    sandbox.stub(numberFormat, 'outcomeScore').returns(this.ret)
  },
})

test('proxies to numberFormat', function () {
  const num = 2.34
  const format = 'outcomeScore'
  equal(helpers.nf(num, {hash: {format}}), this.ret)
  ok(numberFormat.outcomeScore.calledWithMatch(num))
})

QUnit.module('eachWithIndex', hooks => {
  let items
  let itemFunc

  hooks.beforeEach(() => {
    items = [{text: 'a'}, {text: 'b'}, {text: 'c'}]
    itemFunc = element => `<p>Item ${element._index}: ${element.text}</p>`
  })

  test('assigns the value of startingValue to the _index variable', () => {
    const output = helpers.eachWithIndex(items, {hash: {startingValue: 1}, fn: itemFunc})

    strictEqual(output, '<p>Item 1: a</p><p>Item 2: b</p><p>Item 3: c</p>')
  })

  test('defaults to 0 if no startingValue is specified', () => {
    const output = helpers.eachWithIndex(items, {hash: {}, fn: itemFunc})

    strictEqual(output, '<p>Item 0: a</p><p>Item 1: b</p><p>Item 2: c</p>')
  })
})

QUnit.module('linkify helper')

test('linkifies plaintext links into html links', function () {
  const text = 'Make a reservation at http://google.com/reserve'
  const html =
    "Make a reservation at <a href='http:&#x2F;&#x2F;google.com&#x2F;reserve'>http:&#x2F;&#x2F;google.com&#x2F;reserve</a>"
  equal(helpers.linkify(text), html)
})
