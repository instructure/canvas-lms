/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import DatetimeField, {
  DATE_FORMAT_OPTIONS,
  DATETIME_FORMAT_OPTIONS,
  TIME_FORMAT_OPTIONS,
} from '@canvas/datetime/jquery/DatetimeField'
import '@canvas/datetime/jquery'
import $ from 'jquery'
import 'jquery-migrate'
import * as tz from '@canvas/datetime'
import tzInTest from '@canvas/datetime/specHelpers'
import timezone from 'timezone'
import detroit from 'timezone/America/Detroit'
import juneau from 'timezone/America/Juneau'
import fakeENV from 'helpers/fakeENV'
import moment from 'moment'

const moonwalk = new Date('1969-07-21T02:56:00Z')
const john_glenn = new Date('1962-02-20T14:47:39')

QUnit.module('processTimeOptions', {
  setup() {
    this.$field = $('<input type="text" name="due_at">')
    this.field = new DatetimeField(this.$field, {})
  },
})

test('should include date and time, but not always time, by default', function () {
  this.field.processTimeOptions({})
  ok(this.field.showDate, 'showDate is true')
  ok(this.field.allowTime, 'allowTime is true')
  ok(!this.field.alwaysShowTime, 'alwaysShowTime is false')
})

test('should disallow time with dateOnly option true', function () {
  this.field.processTimeOptions({dateOnly: true})
  ok(!this.field.allowTime, 'allowTime is false')
})

test('should hide date and always show time with timeOnly option true', function () {
  this.field.processTimeOptions({timeOnly: true})
  ok(!this.field.showDate, 'showDate is false')
  ok(this.field.alwaysShowTime, 'alwaysShowTime is true')
})

test('should allow forcing always show time', function () {
  this.field.processTimeOptions({alwaysShowTime: true})
  ok(this.field.alwaysShowTime, 'alwaysShowTime is true')
})

test('should ignore alwaysShowTime with dateOnly option true', function () {
  this.field.processTimeOptions({dateOnly: true, alwaysShowTime: true})
  ok(!this.field.alwaysShowTime, 'alwaysShowTime is false')
})

test('should ignore both dateOnly and timeOnly if both true', function () {
  this.field.processTimeOptions({dateOnly: true, timeOnly: true})
  ok(this.field.showDate, 'showDate is true')
  ok(this.field.allowTime, 'allowTime is true')
})

QUnit.module('addDatePicker', {
  setup() {
    this.$field = $('<input type="text" name="due_at">')
    // timeOnly=true to prevent creation of the datepicker before we do it in
    // the individual tests
    this.field = new DatetimeField(this.$field, {timeOnly: true})
  },
})

test('should wrap field in .input-append', function () {
  this.field.addDatePicker({})
  const $wrapper = this.$field.parent()
  ok($wrapper.hasClass('input-append'), 'parent has class .input-append')
})

test('should the wrapper', function () {
  const result = this.field.addDatePicker({})
  equal(result[0], this.$field.parent()[0])
})

test('should add datepicker trigger sibling', function () {
  this.field.addDatePicker({})
  const $sibling = this.$field.next()
  ok($sibling.hasClass('ui-datepicker-trigger'), 'has datepicker trigger sibling')
})

test('should hide datepicker trigger from aria and tab', function () {
  this.field.addDatePicker({})
  const $trigger = this.$field.next()
  equal($trigger.attr('aria-hidden'), 'true', 'hidden from aria')
  equal($trigger.attr('tabindex'), '-1', 'hidden from tab order')
})

test('should allow providing datepicker options', function () {
  this.field.addDatePicker({datepicker: {buttonText: 'pick me!'}})
  const $trigger = this.$field.next()
  equal($trigger.text(), 'pick me!', 'used provided buttonText')
})

test('uses first day of week for moment locale', function () {
  const momentLocale = 'MOMENT_LOCALE'
  const firstDayOfWeek = 1
  fakeENV.setup({MOMENT_LOCALE: momentLocale})
  sandbox.stub(moment, 'localeData').returns({firstDayOfWeek: () => firstDayOfWeek})
  sandbox.stub(this.$field, 'datepicker')
  this.field.addDatePicker({})
  ok(moment.localeData.calledWith(momentLocale))
  ok(this.$field.datepicker.calledWithMatch({firstDay: firstDayOfWeek}))
  fakeENV.teardown()
})

QUnit.module('addSuggests', {
  setup() {
    this.$field = $('<input type="text" name="due_at">')
    this.field = new DatetimeField(this.$field, {})

    // undo so we can verify it was redone (or not) in the tests
    if (this.field.$suggest) this.field.$suggest.remove()
    if (this.field.$contextSuggest) this.field.$contextSuggest.remove()

    this.field.$suggest = this.field.$contextSuggest = null
  },
})

test('should add suggest field', function () {
  this.field.addSuggests(this.$field)
  ok(this.field.$suggest)
  equal(this.$field.next()[0], this.field.$suggest[0])
})

test('should not add course suggest field by default', function () {
  this.field.addSuggests(this.$field)
  ok(!this.field.$contextSuggest)
})

test('should add course suggest field if ENV.CONTEXT_TIMEZONE differs', function () {
  fakeENV.setup({TIMEZONE: 'America/Detroit', CONTEXT_TIMEZONE: 'America/Juneau'})
  this.field.addSuggests(this.$field)
  ok(this.field.$contextSuggest)
  equal(this.field.$suggest.next()[0], this.field.$contextSuggest[0])
  fakeENV.teardown()
})

QUnit.module('constructor', {
  setup() {
    tzInTest.configureAndRestoreLater({
      tz: timezone(detroit, 'America/Detroit'),
      tzData: {
        'America/Detroit': detroit,
      },
    })
    fakeENV.setup({TIMEZONE: 'America/Detroit'})
    this.$field = $('<input type="text" name="due_at">')
  },

  teardown() {
    fakeENV.teardown()
    tzInTest.restore()
  },
})

test('should add datepicker by default', function () {
  new DatetimeField(this.$field, {})
  equal(this.$field.parent().length, 1, 'datepicker added')
})

test('should not add datepicker when timeOnly', function () {
  new DatetimeField(this.$field, {timeOnly: true})
  equal(this.$field.parent().length, 0, 'datepicker not added')
})

test('should place suggest outside wrapper when adding datepicker', function () {
  const $wrapper = $('<div></div>').appendTo('body')
  this.$field.appendTo($wrapper)
  const field = new DatetimeField(this.$field, {})
  equal(this.$field.parent().next()[0], field.$suggest[0], 'wrapper and suggest are siblings')
  $wrapper.remove()
})

test('should place suggest next to field when not adding datepicker', function () {
  const $wrapper = $('<div></div>').appendTo('body')
  this.$field.appendTo($wrapper)
  const field = new DatetimeField(this.$field, {timeOnly: true})
  equal(this.$field.next()[0], field.$suggest[0], 'field and suggest are siblings')
  $wrapper.remove()
})

test('should set the button to disabled when given the option to do so', function () {
  new DatetimeField(this.$field, {disableButton: true})
  ok(this.$field.next().prop('disabled'))
})

test('should not add hidden input by default', function () {
  new DatetimeField(this.$field, {})
  ok(!this.$field.data('hiddenInput'), 'no hidden input')
  equal(this.$field.attr('name'), 'due_at', 'name preserved on field')
})

test('should add hidden input when requested', function () {
  new DatetimeField(this.$field, {addHiddenInput: true})
  ok(this.$field.data('hiddenInput'), 'hidden input')
  equal(this.$field.data('hiddenInput').attr('name'), 'due_at', 'coopted name')
  equal(this.$field.attr('name'), null, 'name removed from field')
})

test('should initialize from the inputdate data', function () {
  this.$field.data('inputdate', '1969-07-21T02:56:00Z')
  const field = new DatetimeField(this.$field, {})
  equal(field.$suggest.text(), 'Sun, Jul 20, 1969, 9:56 PM')
})

test('should initialize from the initial value attribute if present, and then remove it', function () {
  this.$initialValueField = $(
    '<input type="text" name="has_initial_value" data-initial-value="2021-02-14T14:00:00Z">'
  )
  const field = new DatetimeField(this.$initialValueField, {})
  equal(field.$suggest.text(), 'Sun, Feb 14, 2021, 9:00 AM')
  equal(this.$initialValueField.attr('data-initial-value'), undefined)
})

test('should tie it to update on keyup only', function () {
  const field = new DatetimeField(this.$field, {})

  this.$field.val('Jul 21, 1969 5:56am').trigger('keyup')
  equal(field.$suggest.text(), 'Mon, Jul 21, 1969, 5:56 AM')
})

QUnit.module('setFromValue', {
  setup() {
    tzInTest.configureAndRestoreLater({
      tz: timezone(detroit, 'America/Detroit'),
      tzData: {
        'America/Detroit': detroit,
      },
    })
    fakeENV.setup({TIMEZONE: 'America/Detroit'})
    this.$field = $('<input type="text" name="due_at">')
    this.field = new DatetimeField(this.$field, {})
  },

  teardown() {
    fakeENV.teardown()
    tzInTest.restore()
  },
})

test('should set data fields', function () {
  this.$field.val('Jul 20, 2009 at 10:56pm')
  this.field.setFromValue()
  equal(+this.$field.data('unfudged-date'), new Date('2009-07-21T02:56Z').getTime())
})

test('should set suggest text', function () {
  this.$field.val('Jul 21, 1969 at 2:56am')
  this.field.setFromValue()
  equal(this.field.$suggest.text(), 'Mon, Jul 21, 1969, 2:56 AM')
})

QUnit.module('parseValue', {
  setup() {
    this.$field = $('<input type="text" name="due_at">')
    this.field = new DatetimeField(this.$field, {})
  },
})

test('sets @fudged according to browser (fudged) timezone', function () {
  this.$field.val(tz.format(moonwalk, '%b %-e, %Y at %-l:%M%P')).change()
  this.field.parseValue()
  equal(+this.field.fudged, +$.fudgeDateForProfileTimezone(moonwalk))
})

test('sets @datetime according to profile timezone', function () {
  this.$field.val(tz.format(moonwalk, '%b %-e, %Y at %-l:%M%P')).change()
  this.field.parseValue()
  equal(+this.field.datetime, +moonwalk)
})

test('sets @showTime true by default', function () {
  this.$field.val('Jan 1, 1970 at 12:01am').change()
  this.field.parseValue()
  equal(this.field.showTime, true)
})

test('sets @showTime false when value is midnight in profile timezone', function () {
  this.$field.val('Jan 1, 1970 at 12:00am').change()
  this.field.parseValue()
  equal(this.field.showTime, false)
})

test('sets @showTime true for midnight if @alwaysShowTime', function () {
  this.field.alwaysShowTime = true
  this.$field.val('Jan 1, 1970 at 12:00am').change()
  this.field.parseValue()
  equal(this.field.showTime, true)
})

test('sets @showTime false for non-midnight if not @allowTime', function () {
  this.field.allowTime = false
  this.$field.val('Jan 1, 1970 at 12:01am').change()
  this.field.parseValue()
  equal(this.field.showTime, false)
})

test('sets not @blank and not @invalid on valid input', function () {
  this.$field.val('Jan 1, 1970 at 12:00am').change()
  this.field.parseValue()
  equal(this.field.blank, false)
  equal(this.field.invalid, false)
})

test('sets @blank and not @invalid and null dates when no input', function () {
  this.$field.val('').change()
  this.field.parseValue()
  equal(this.field.blank, true)
  equal(this.field.invalid, false)
  equal(this.field.datetime, null)
  equal(this.field.fudged, null)
})

test('sets @invalid and not @blank and null dates when invalid input', function () {
  this.$field.val('invalid').change()
  this.field.parseValue()
  equal(this.field.blank, false)
  equal(this.field.invalid, true)
  equal(this.field.datetime, null)
  equal(this.field.fudged, null)
})

test('interprets bare numbers < 8 in time-only fields as 12-hour PM', function () {
  this.field.showDate = false
  this.$field.val('7').change()
  this.field.parseValue()
  equal(tz.format(this.field.datetime, '%-l%P'), '7pm')
})

test('interprets bare numbers >= 8 in time-only fields as 24-hour', function () {
  this.field.showDate = false
  this.$field.val('8').change()
  this.field.parseValue()
  equal(tz.format(this.field.datetime, '%-l%P'), '8am')
  this.$field.val('13').change()
  this.field.parseValue()
  equal(tz.format(this.field.datetime, '%-l%P'), '1pm')
})

test('interprets time-only fields as occurring on implicit date if set', function () {
  this.field.showDate = false
  this.field.setDate(moonwalk)
  this.$field.val('12PM').change()
  this.field.parseValue()
  equal(tz.format(this.field.datetime, '%F %T'), `${tz.format(moonwalk, '%F ')}12:00:00`)
})

test('setDate changes the date of an existing time field', function () {
  this.field.showDate = false
  this.field.setDate(moonwalk)
  this.$field.val('12PM').change()
  this.field.setDate(john_glenn)
  equal(tz.format(this.field.datetime, '%F %T'), `${tz.format(john_glenn, '%F ')}12:00:00`)
})

QUnit.module('updateData', {
  setup() {
    tzInTest.configureAndRestoreLater({
      tz: timezone(detroit, 'America/Detroit'),
      tzData: {
        'America/Detroit': detroit,
      },
    })
    fakeENV.setup({TIMEZONE: 'America/Detroit'})

    this.$field = $('<input type="text" name="due_at">')
    this.$field.val('Jan 1, 1970 at 12:01am')
    this.field = new DatetimeField(this.$field, {})
    this.field.datetime = moonwalk
    this.field.fudged = $.fudgeDateForProfileTimezone(moonwalk)
  },

  teardown() {
    fakeENV.teardown()
    tzInTest.restore()
  },
})

test('sets date field to fudged time', function () {
  this.field.updateData()
  equal(+this.$field.data('date'), +this.field.fudged)
})

test('sets unfudged-date field to actual time', function () {
  this.field.updateData()
  equal(+this.$field.data('unfudged-date'), +moonwalk)
})

test('sets invalid field', function () {
  this.field.updateData()
  equal(this.$field.data('invalid'), false)
})

test('sets blank field', function () {
  this.field.updateData()
  equal(this.$field.data('blank'), false)
})

test('sets value of hiddenInput, if present, to fudged time as ISO8601', function () {
  this.field.addHiddenInput()
  this.field.updateData()
  equal(this.$field.data('hiddenInput').val(), this.field.fudged.toISOString())
})

test('sets time-* to fudged, 12-hour values', function () {
  this.field.updateData()
  equal(this.$field.data('time-hour'), '9')
  equal(this.$field.data('time-minute'), '56')
  equal(this.$field.data('time-ampm'), 'PM')
})

test('sets time-* to fudged, 24-hour values', function () {
  ENV.LOCALE = 'pt-BR'
  this.field.updateData()
  equal(this.$field.data('time-hour'), '21')
  equal(this.$field.data('time-minute'), '56')
  equal(this.$field.data('time-ampm'), null)
})

test('only sets time-* if for full datetime field', function () {
  this.$field.removeData('time-hour')
  this.field.showDate = false
  this.field.updateData()
  equal(this.$field.data('time-hour'), undefined)
  this.field.allowTime = false
  this.field.updateData()
  equal(this.$field.data('time-hour'), undefined)
})

test('clear time-* to null if blank', function () {
  this.field.blank = true
  this.field.updateData()
  equal(this.$field.data('time-hour'), null)
})

test('clear time-* to null if invalid', function () {
  this.field.invalid = true
  this.field.updateData()
  equal(this.$field.data('time-hour'), null)
})

test('clear time-* to null if not @showTime (midnight)', function () {
  this.field.showTime = false
  this.field.updateData()
  equal(this.$field.data('time-hour'), null)
})

QUnit.module('updateSuggest', {
  setup() {
    this.$field = $('<input type="text" name="due_at">')
    this.field = new DatetimeField(this.$field, {})
  },
})

test('puts formatSuggest result in suggest text', function () {
  const value = 'suggested value'
  this.field.formatSuggest = () => value
  this.field.updateSuggest()
  equal(this.field.$suggest.text(), value)
})

test('puts non-empty formatSuggestContext result w/ Course prefix in course suggest text', function () {
  const value = 'suggested course value'
  const $contextSuggest = $('<div>')
  this.field.$contextSuggest = $contextSuggest
  this.field.formatSuggestContext = () => value
  this.field.updateSuggest()
  equal(this.field.$contextSuggest.text(), `Course: ${value}`)
})

test('adds Local prefix to suggest text if non-empty formatSuggestContext result', function () {
  this.field.$contextSuggest = $('<div>')
  this.field.formatSuggestContext = () => 'non-empty'
  this.field.updateSuggest()
  equal(this.field.$suggest.text(), `Local: ${this.field.formatSuggest()}`)
})

test('omits course suggest text if formatSuggestContext is empty', function () {
  this.field.$contextSuggest = $('<div>')
  this.field.formatSuggestContext = () => ''
  this.field.updateSuggest()
  equal(this.field.$suggest.text(), this.field.formatSuggest())
  equal(this.field.$contextSuggest.text(), '')
})

test('adds invalid_datetime class to suggest if invalid', function () {
  this.field.updateSuggest()
  ok(!this.field.$suggest.hasClass('invalid_datetime'))
  this.field.invalid = true
  this.field.updateSuggest()
  ok(this.field.$suggest.hasClass('invalid_datetime'))
})

QUnit.module('alertScreenreader', {
  setup() {
    this.$field = $('<input type="text" name="due_at">')
    this.field = new DatetimeField(this.$field, {})
    // our version of lodash doesn't play nice with sinon fake timers, so it's
    // not feasible to confirm $.screenReaderFlashMessageExclusive itself gets
    // called. but we can confirm this step, despite the coupling to
    // implementation
    sandbox.spy(this.field, 'debouncedSRFME')
  },
})

test('should alert screenreader on an invalid parse no matter what', function () {
  this.$field.val('invalid')
  this.$field.change()
  ok(this.field.debouncedSRFME.withArgs("That's not a date!").called)
})

test('flashes suggest text to screenreader on typed input', function () {
  const value = 'suggested value'
  this.field.formatSuggest = () => value
  this.$field.keyup()
  ok(this.field.debouncedSRFME.withArgs(value).called)
})

test('flashes combined suggest text to screenreader when there is course suggest text', function () {
  this.field.$contextSuggest = $('<div>')
  const localValue = 'suggested value'
  const courseValue = 'suggested course value'
  const combinedValue = `Local: ${localValue}\nCourse: ${courseValue}`
  this.field.formatSuggest = () => localValue
  this.field.formatSuggestContext = () => courseValue
  this.$field.change()
  ok(this.field.debouncedSRFME.withArgs(combinedValue).called)
})

test('does not reflash same suggest text when key presses do not change anything', function () {
  const value = 'suggested value'
  this.field.formatSuggest = () => value
  this.$field.keyup()
  ok(this.field.debouncedSRFME.withArgs(value).calledOnce)
  this.$field.keyup()
  ok(this.field.debouncedSRFME.withArgs(value).calledOnce)
})

// TODO: add spec asserting actual call to $.screenReaderFlashMessageExclusive
// is debounced, so e.g. three triggers with different suggest values within
// ~100ms only actually creates one alert. will require upgrading lodash first
// so we can use debounced.flush()

QUnit.module('formatSuggest', {
  setup() {
    tzInTest.configureAndRestoreLater({
      tz: timezone(detroit, 'America/Detroit'),
      tzData: {'America/Detroit': detroit},
    })
    fakeENV.setup({TIMEZONE: 'America/Detroit'})
    this.$field = $('<input type="text" name="due_at">')
    this.$field.val('Jul 20, 1969 at 9:56pm')
    this.field = new DatetimeField(this.$field, {})
  },

  teardown() {
    fakeENV.teardown()
    tzInTest.restore()
  },
})

test('returns result formatted in profile timezone', function () {
  equal(this.field.formatSuggest(), 'Sun, Jul 20, 1969, 9:56 PM')
})

test('returns "" if @blank', function () {
  this.field.blank = true
  equal(this.field.formatSuggest(), '')
})

test('returns error message if @invalid', function () {
  this.field.invalid = true
  equal(this.field.formatSuggest(), this.field.parseError)
})

test('returns date only if @showTime false', function () {
  this.field.showTime = false
  equal(this.field.formatSuggest(), 'Sun, Jul 20, 1969')
})

test('returns time only if @showDate false', function () {
  this.field.showDate = false
  equal(this.field.formatSuggest(), '9:56 PM')
})

test('localizes formatting of dates and times', function () {
  ENV.LOCALE = 'pt-BR'
  equal(this.field.formatSuggest(), 'dom., 20 de jul. de 1969, 21:56')
})

QUnit.module('formatSuggestContext', {
  setup() {
    tzInTest.configureAndRestoreLater({
      tz: timezone(detroit, 'America/Detroit'),
      tzData: {
        'America/Detroit': detroit,
        'America/Juneau': juneau,
      },
    })
    fakeENV.setup({TIMEZONE: 'America/Detroit', CONTEXT_TIMEZONE: 'America/Juneau'})
    this.$field = $('<input type="text" name="due_at">')
    this.$field.val('Jul 20, 1969 at 9:56pm')
    this.field = new DatetimeField(this.$field, {})
  },

  teardown() {
    fakeENV.teardown()
    tzInTest.restore()
  },
})

test('returns result formatted in course timezone', function () {
  equal(this.field.formatSuggestContext(), 'Sun, Jul 20, 1969, 7:56 PM')
})

test('returns "" if @blank', function () {
  this.field.blank = true
  equal(this.field.formatSuggestContext(), '')
})

test('returns "" if @invalid', function () {
  this.field.invalid = true
  equal(this.field.formatSuggestContext(), '')
})

test('returns "" if @showTime false', function () {
  this.field.showTime = false
  equal(this.field.formatSuggestContext(), '')
})

test('returns time only if @showDate false', function () {
  this.field.showDate = false
  equal(this.field.formatSuggestContext(), '7:56 PM')
})

QUnit.module('normalizeValue', {
  setup() {
    this.$field = $('<input type="text" name="due_at">')
    this.field = new DatetimeField(this.$field, {})
  },
})

test('trims whitespace', function () {
  equal(this.field.normalizeValue('  abc  '), 'abc')
  equal(this.field.normalizeValue('  '), '')
})

test('just passes through null and undefined', function () {
  equal(this.field.normalizeValue(null), null)
  equal(this.field.normalizeValue(undefined), undefined)
})

test('does nothing else when @showDate is true', function () {
  this.field.showDate = true
  equal(this.field.normalizeValue('0'), '0')
})

test('passes through non-hour string even when @showDate is false', function () {
  this.field.showDate = false
  equal(this.field.normalizeValue('123'), '123')
  equal(this.field.normalizeValue('12a'), '12a')
  equal(this.field.normalizeValue('b12'), 'b12')
})

test('treats leading zero as 24-hour time', function () {
  this.field.showDate = false
  equal(this.field.normalizeValue('0'), '0:00')
  equal(this.field.normalizeValue('00'), '00:00')
  equal(this.field.normalizeValue('01'), '01:00')
  equal(this.field.normalizeValue('09'), '09:00')
})

test('treats 1 through 7 as 12-hour pm time', function () {
  this.field.showDate = false
  equal(this.field.normalizeValue('1'), '1pm')
  equal(this.field.normalizeValue('7'), '7pm')
})

test('treats 8 through 23 as 24-hour time', function () {
  this.field.showDate = false
  equal(this.field.normalizeValue('8'), '8:00')
  equal(this.field.normalizeValue('11'), '11:00')
  equal(this.field.normalizeValue('12'), '12:00')
  equal(this.field.normalizeValue('23'), '23:00')
})

test('passes through 24 and greater', function () {
  this.field.showDate = false
  equal(this.field.normalizeValue('24'), '24')
  equal(this.field.normalizeValue('25'), '25')
  equal(this.field.normalizeValue('99'), '99')
})

QUnit.module('setFormattedDatetime', {
  setup() {
    tzInTest.configureAndRestoreLater({
      tz: timezone(detroit, 'America/Detroit'),
      tzData: {
        'America/Detroit': detroit,
      },
    })
    fakeENV.setup({TIMEZONE: 'America/Detroit'})

    this.$field = $('<input type="text" name="due_at">')
    this.field = new DatetimeField(this.$field, {})
  },

  teardown() {
    fakeENV.teardown()
    tzInTest.restore()
  },
})

test('sets to blank with null value', function () {
  this.field.setFormattedDatetime(null, DATETIME_FORMAT_OPTIONS)
  equal(this.field.datetime, null)
  equal(this.field.fudged, null)
  equal(this.field.blank, true)
  equal(this.field.invalid, false)
  equal(this.$field.val(), '')
})

test('treats value as unfudged', function () {
  this.field.setFormattedDatetime(moonwalk, DATETIME_FORMAT_OPTIONS)
  equal(+this.field.datetime, +moonwalk)
  equal(+this.field.fudged, +$.fudgeDateForProfileTimezone(moonwalk))
  equal(this.field.blank, false)
  equal(this.field.invalid, false)
  equal(this.$field.val(), 'Sun, Jul 20, 1969, 9:56 PM')
})

test('formats value into val() according to date/time requests', function () {
  this.field.setFormattedDatetime(moonwalk, DATE_FORMAT_OPTIONS)
  equal(this.$field.val(), 'Sun, Jul 20, 1969')
  this.field.setFormattedDatetime(moonwalk, TIME_FORMAT_OPTIONS)
  equal(this.$field.val(), '9:56 PM')
})

test('localizes value', function () {
  ENV.LOCALE = 'de'
  this.field.setFormattedDatetime(moonwalk, DATETIME_FORMAT_OPTIONS)
  equal(this.$field.val(), 'So., 20. Juli 1969, 21:56')
})

QUnit.module('setDate/setTime/setDatetime', {
  setup() {
    tzInTest.configureAndRestoreLater({
      tz: timezone(detroit, 'America/Detroit'),
      tzData: {
        'America/Detroit': detroit,
      },
    })
    fakeENV.setup({TIMEZONE: 'America/Detroit'})
    this.$field = $('<input type="text" name="due_at">')
    this.field = new DatetimeField(this.$field, {})
  },

  teardown() {
    fakeENV.teardown()
    tzInTest.restore()
  },
})

test('setDate formats into val() with just date', function () {
  this.field.setDate(moonwalk)
  equal(this.$field.val(), 'Sun, Jul 20, 1969')
})

test('setTime formats into val() with just time', function () {
  this.field.setTime(moonwalk)
  equal(this.$field.val(), '9:56 PM')
})

test('setDatetime formats into val() with full date and time', function () {
  this.field.setDatetime(moonwalk)
  equal(this.$field.val(), 'Sun, Jul 20, 1969, 9:56 PM')
})
