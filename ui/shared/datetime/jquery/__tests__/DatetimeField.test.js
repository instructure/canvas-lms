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

import DatetimeField, {DATETIME_FORMAT_OPTIONS, PARSE_RESULTS} from '../DatetimeField'
import {fudgeDateForProfileTimezone} from '@instructure/moment-utils'
import $ from 'jquery'
import 'jquery-migrate'
import * as tz from '@instructure/moment-utils'
import tzInTest from '@instructure/moment-utils/specHelpers'
import timezone from 'timezone'
import detroit from 'timezone/America/Detroit'
import juneau from 'timezone/America/Juneau'
import moment from 'moment'
import fakeENV from '@canvas/test-utils/fakeENV'

const challenger = new Date('1986-01-28T16:39:00Z')
const columbia = new Date('2003-02-01T13:59:00Z')

describe('DatetimeField', () => {
  let $field
  let field

  beforeEach(() => {
    fakeENV.setup()
    // Mock moment.localeData to provide firstDayOfWeek method
    jest.spyOn(moment, 'localeData').mockImplementation(locale => ({
      firstDayOfWeek: () => 0,
      longDateFormat: _format => (locale === 'es' ? 'DD/MM/YYYY' : 'MM/DD/YYYY'),
    }))
  })

  afterEach(() => {
    fakeENV.teardown()
    $field?.remove()
    moment.localeData.mockRestore()
  })

  const createField = (options = {}) => {
    $field = $('<input type="text" name="due_at">')
    field = new DatetimeField($field, options)
    return field
  }

  describe('processTimeOptions', () => {
    beforeEach(() => {
      jest.spyOn(console, 'warn').mockImplementation(() => {})
      createField()
    })

    afterEach(() => {
      console.warn.mockRestore()
    })

    it('includes date and time, but not always time, by default', () => {
      field.processTimeOptions({timeOnly: false, alwaysShowTime: false})
      expect(field.showDate).toBe(true)
      expect(field.allowTime).toBe(true)
      expect(field.alwaysShowTime).toBe(false)
    })

    it('disallows time with dateOnly option true', () => {
      field.processTimeOptions({dateOnly: true})
      expect(field.allowTime).toBe(false)
    })

    it('hides date and always shows time with timeOnly option true', () => {
      field.processTimeOptions({timeOnly: true})
      expect(field.showDate).toBe(false)
      expect(field.alwaysShowTime).toBe(true)
    })

    it('allows forcing always show time', () => {
      field.processTimeOptions({alwaysShowTime: true})
      expect(field.alwaysShowTime).toBe(true)
    })

    it('ignores alwaysShowTime with dateOnly option true', () => {
      field.processTimeOptions({dateOnly: true, alwaysShowTime: true})
      expect(field.alwaysShowTime).toBe(false)
    })

    it('ignores both dateOnly and timeOnly if both true', () => {
      field.processTimeOptions({dateOnly: true, timeOnly: true})
      expect(field.showDate).toBe(true)
      expect(field.allowTime).toBe(true)
    })
  })

  describe('addDatePicker', () => {
    beforeEach(() => {
      createField({timeOnly: true})
    })

    it('wraps field in .input-append', () => {
      field.addDatePicker({})
      const $wrapper = $field.parent()
      expect($wrapper.hasClass('input-append')).toBe(true)
    })

    it('returns the wrapper', () => {
      const result = field.addDatePicker({})
      expect(result[0]).toBe($field.parent()[0])
    })

    it('adds datepicker trigger sibling', () => {
      field.addDatePicker({})
      const $sibling = $field.next()
      expect($sibling.hasClass('ui-datepicker-trigger')).toBe(true)
    })

    it('hides datepicker trigger from aria and tab', () => {
      field.addDatePicker({})
      const $trigger = $field.next()
      expect($trigger.attr('aria-hidden')).toBe('true')
      expect($trigger.attr('tabindex')).toBe('-1')
    })

    it('allows providing datepicker options', () => {
      field.addDatePicker({datepicker: {buttonText: 'pick me!'}})
      const $trigger = $field.next()
      expect($trigger.text()).toBe('pick me!')
    })

    it('uses first day of week for moment locale', () => {
      const momentLocale = 'MOMENT_LOCALE'
      const firstDayOfWeek = 1
      ENV.MOMENT_LOCALE = momentLocale
      jest.spyOn(moment, 'localeData').mockReturnValue({firstDayOfWeek: () => firstDayOfWeek})
      const datepickerSpy = jest.spyOn($field, 'datepicker')
      field.addDatePicker({})
      expect(moment.localeData).toHaveBeenCalledWith(momentLocale)
      expect(datepickerSpy).toHaveBeenCalledWith(
        expect.objectContaining({firstDay: firstDayOfWeek}),
      )
    })
  })

  describe('addSuggests', () => {
    beforeEach(() => {
      createField()
      if (field.$suggest) field.$suggest.remove()
      if (field.$contextSuggest) field.$contextSuggest.remove()
      field.$suggest = field.$contextSuggest = null
    })

    it('adds suggest field', () => {
      field.addSuggests($field)
      expect(field.$suggest).toBeTruthy()
      expect($field.next()[0]).toBe(field.$suggest[0])
    })

    it('does not add course suggest field by default', () => {
      field.addSuggests($field)
      expect(field.$contextSuggest).toBeFalsy()
    })

    it('adds course suggest field if ENV.CONTEXT_TIMEZONE differs', () => {
      ENV.TIMEZONE = 'America/Detroit'
      ENV.CONTEXT_TIMEZONE = 'America/Juneau'
      field.addSuggests($field)
      expect(field.$contextSuggest).toBeTruthy()
      expect(field.$suggest.next()[0]).toBe(field.$contextSuggest[0])
    })
  })

  describe('constructor', () => {
    beforeEach(() => {
      tzInTest.configureAndRestoreLater({
        tz: timezone(detroit, 'America/Detroit'),
        tzData: {
          'America/Detroit': detroit,
        },
      })
      ENV.TIMEZONE = 'America/Detroit'
      $field = $('<input type="text" name="due_at">')
    })

    afterEach(() => {
      tzInTest.restore()
    })

    it('adds datepicker by default', () => {
      new DatetimeField($field, {})
      expect($field.parent()).toHaveLength(1)
    })

    it('does not add datepicker when timeOnly', () => {
      new DatetimeField($field, {timeOnly: true})
      expect($field.parent()).toHaveLength(0)
    })

    it('places suggest outside wrapper when adding datepicker', () => {
      const $wrapper = $('<div></div>').appendTo(document.body)
      $field.appendTo($wrapper)
      const field = new DatetimeField($field, {})
      expect($field.parent().next()[0]).toBe(field.$suggest[0])
      $wrapper.remove()
    })

    it('places suggest next to field when not adding datepicker', () => {
      const $wrapper = $('<div></div>').appendTo(document.body)
      $field.appendTo($wrapper)
      const field = new DatetimeField($field, {timeOnly: true})
      expect($field.next()[0]).toBe(field.$suggest[0])
      $wrapper.remove()
    })
  })

  describe('setFromValue', () => {
    beforeEach(() => {
      createField()
      field.datetime = new Date('2009-07-20T22:56:00')
      field.fudged = fudgeDateForProfileTimezone(field.datetime)
      field.showDate = true
      field.allowTime = true
      field.parseValue = jest.fn()
      field.update = jest.fn()
      field.updateSuggest = jest.fn()
    })

    it('sets data fields', () => {
      $field.val('Jul 20, 2009 at 10:56pm')
      field.setFromValue()
      expect(field.parseValue).toHaveBeenCalled()
      expect(field.update).toHaveBeenCalled()
    })
  })

  describe('parseValue', () => {
    beforeEach(() => {
      tzInTest.configureAndRestoreLater({
        tz: timezone(detroit, 'America/Detroit'),
        tzData: {
          'America/Detroit': detroit,
        },
      })
      ENV.TIMEZONE = 'America/Detroit'
      createField()
    })

    afterEach(() => {
      tzInTest.restore()
    })

    it('sets fudged according to browser (fudged) timezone', () => {
      $field.val(tz.format(challenger, '%b %-e, %Y at %-l:%M%P')).change()
      field.parseValue()
      expect(+field.fudged).toBe(+fudgeDateForProfileTimezone(challenger))
    })
  })

  describe('updateData', () => {
    beforeEach(() => {
      createField()
      field.datetime = challenger
      field.fudged = fudgeDateForProfileTimezone(challenger)
    })

    it('sets date field to fudged time', () => {
      field.updateData()
      expect(+$field.data('date')).toBe(+field.fudged)
    })
  })

  describe('updateSuggest', () => {
    beforeEach(() => {
      createField()
      field.$suggest = $('<div>')
      field.$contextSuggest = $('<div>')
    })

    it('puts formatSuggest result in suggest text', () => {
      const value = 'suggested value'
      jest.spyOn(field, 'formatSuggest').mockReturnValue(value)
      field.updateSuggest()
      expect(field.$suggest.text()).toBe(value)
    })

    it('puts non-empty formatSuggestContext result with Course prefix in course suggest text', () => {
      const value = 'context value'
      jest.spyOn(field, 'formatSuggestContext').mockReturnValue(value)
      field.updateSuggest()
      expect(field.$contextSuggest.text()).toBe(`Course: ${value}`)
    })

    it('adds Local prefix to suggest text if non-empty formatSuggestContext result', () => {
      const value = 'context value'
      jest.spyOn(field, 'formatSuggestContext').mockReturnValue(value)
      const suggestValue = 'suggested value'
      jest.spyOn(field, 'formatSuggest').mockReturnValue(suggestValue)
      field.updateSuggest()
      expect(field.$suggest.text()).toBe(`Local: ${suggestValue}`)
    })

    it('omits course suggest text if formatSuggestContext is empty', () => {
      jest.spyOn(field, 'formatSuggestContext').mockReturnValue('')
      const suggestValue = 'suggested value'
      jest.spyOn(field, 'formatSuggest').mockReturnValue(suggestValue)
      field.updateSuggest()
      expect(field.$suggest.text()).toBe(suggestValue)
      expect(field.$contextSuggest.text()).toBe('')
    })

    describe('with showFormatExample option', () => {
      beforeEach(() => {
        createField({showFormatExample: true})
        field.$formatExample = $('<div>')
      })

      it('shows example format when blank', () => {
        field.blank = true
        field.updateSuggest()
        expect(field.$formatExample.text()).toBe('MM/DD/YYYY')
      })

      it('does not show example format while typing', () => {
        field.blank = false
        const value = '12/31/2020'
        jest.spyOn(field, 'formatSuggest').mockReturnValue(value)
        field.updateSuggest(true)
        expect(field.$formatExample.text()).toBe('')
      })

      it('shows example format when contextsuggest is present', () => {
        ENV.TIMEZONE = 'America/Detroit'
        ENV.CONTEXT_TIMEZONE = 'America/Juneau'
        field.blank = true
        field.updateSuggest()
        expect(field.$formatExample.text()).toBe('MM/DD/YYYY')
      })

      it('shows example format based on locale', () => {
        ENV.MOMENT_LOCALE = 'es'
        field.blank = true
        field.updateSuggest()
        expect(field.$formatExample.text()).toBe('DD/MM/YYYY')
      })

      it('does not show example format when timeonly is true', () => {
        createField({showFormatExample: true, timeOnly: true})
        field.blank = true
        field.updateSuggest()
        expect(field.$formatExample.text()).toBe('')
      })
    })
  })

  describe('screenreader alerts', () => {
    beforeEach(() => {
      createField()
      field.debouncedSRFME = jest.fn()
    })

    it('alerts screenreader on an invalid parse no matter what', () => {
      $field.val('invalid')
      $field.change()
      expect(field.debouncedSRFME).toHaveBeenCalledWith('Please enter a valid format for a date')
    })

    it('flashes combined suggest text to screenreader when there is course suggest text', () => {
      const value = 'suggested value'
      const contextValue = 'context value'
      const combinedValue = `Local: ${value}\nCourse: ${contextValue}`
      jest.spyOn(field, 'formatSuggest').mockReturnValue(value)
      jest.spyOn(field, 'formatSuggestContext').mockReturnValue(contextValue)
      field.$suggest = $('<div>').text(`Local: ${value}`)
      field.$contextSuggest = $('<div>').text(`Course: ${contextValue}`)
      $field.change()
      expect(field.debouncedSRFME).toHaveBeenCalledWith(combinedValue)
    })

    it('does not reflash same suggest text when key presses do not change anything', () => {
      const value = 'suggested value'
      jest.spyOn(field, 'formatSuggest').mockReturnValue(value)
      $field.keyup()
      expect(field.debouncedSRFME).toHaveBeenCalledTimes(1)
      expect(field.debouncedSRFME).toHaveBeenCalledWith(value)
      $field.keyup()
      expect(field.debouncedSRFME).toHaveBeenCalledTimes(1)
    })
  })

  describe('formatSuggest', () => {
    beforeEach(() => {
      tzInTest.configureAndRestoreLater({
        tz: timezone(detroit, 'America/Detroit'),
        tzData: {
          'America/Detroit': detroit,
        },
      })
      ENV.TIMEZONE = 'America/Detroit'
      createField()
      field.datetime = challenger
      field.fudged = fudgeDateForProfileTimezone(challenger)
      field.showDate = true
      field.allowTime = true
      field.alwaysShowTime = true
      field.blank = false
      field.valid = PARSE_RESULTS.VALID
    })

    afterEach(() => {
      tzInTest.restore()
    })

    it('returns result formatted in profile timezone', () => {
      expect(field.formatSuggest()).toBe('Tue, Jan 28, 1986, 11:39 AM')
    })
  })

  describe('formatSuggestContext', () => {
    beforeEach(() => {
      tzInTest.configureAndRestoreLater({
        tz: timezone(detroit, 'America/Detroit'),
        tzData: {
          'America/Detroit': detroit,
          'America/Juneau': juneau,
        },
      })
      ENV.TIMEZONE = 'America/Detroit'
      ENV.CONTEXT_TIMEZONE = 'America/Juneau'
      createField()
      field.datetime = challenger
      field.fudged = fudgeDateForProfileTimezone(challenger)
      field.showDate = true
      field.allowTime = true
      field.alwaysShowTime = true
      field.blank = false
      field.valid = PARSE_RESULTS.VALID
      field.contextTimezone = 'America/Juneau'
    })

    afterEach(() => {
      tzInTest.restore()
    })

    it('returns result formatted in course timezone', () => {
      expect(field.formatSuggestContext()).toBe('Tue, Jan 28, 1986, 7:39 AM')
    })
  })

  describe('normalizeValue', () => {
    beforeEach(() => {
      createField()
    })

    it('trims whitespace', () => {
      expect(field.normalizeValue('  abc  ')).toBe('abc')
      expect(field.normalizeValue('  ')).toBe('')
    })
  })

  describe('setFormattedDatetime', () => {
    beforeEach(() => {
      tzInTest.configureAndRestoreLater({
        tz: timezone(detroit, 'America/Detroit'),
        tzData: {
          'America/Detroit': detroit,
        },
      })
      ENV.TIMEZONE = 'America/Detroit'
      createField()
    })

    afterEach(() => {
      tzInTest.restore()
    })

    it('sets to blank with null value', () => {
      field.setFormattedDatetime(null, DATETIME_FORMAT_OPTIONS)
      expect(field.datetime).toBeNull()
    })
  })

  describe('setDate', () => {
    beforeEach(() => {
      tzInTest.configureAndRestoreLater({
        tz: timezone(detroit, 'America/Detroit'),
        tzData: {
          'America/Detroit': detroit,
        },
      })
      ENV.TIMEZONE = 'America/Detroit'
      createField()
    })

    afterEach(() => {
      tzInTest.restore()
    })

    it('formats into val() with just date', () => {
      field.setDate(challenger)
      expect($field.val()).toBe('Tue, Jan 28, 1986')
    })
  })

  describe('getFormatExample', () => {
    beforeEach(() => {
      createField()
    })

    it('returns example date format', () => {
      fakeENV.setup({
        MOMENT_LOCALE: 'en',
      })
      expect(field.getFormatExample()).toBe('MM/DD/YYYY')
    })

    it('returns example date format based on locale', () => {
      fakeENV.setup({
        MOMENT_LOCALE: 'es',
      })
      expect(field.getFormatExample()).toBe('DD/MM/YYYY')
    })

    it('returns empty string when timeOnly is true', () => {
      createField({timeOnly: true})
      expect(field.getFormatExample()).toBe('')
    })
  })
})
