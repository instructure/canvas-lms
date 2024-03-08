/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import * as tz from '@canvas/datetime'
import enrollmentName from './enrollmentName'
import _Handlebars from 'handlebars/runtime'
import I18nObj, {useScope as useI18nScope} from '@canvas/i18n' //  'i18nObj' gets the extended I18n object with all the extra functions (interpolate, strftime, ...)
import $ from 'jquery'
import {chain, defaults, isDate, map, reduce} from 'lodash'
import htmlEscape, {raw} from '@instructure/html-escape'
import semanticDateRange from '@canvas/datetime/semanticDateRange'
import dateSelect from './dateSelect'
import mimeClass from '@canvas/mime/mimeClass'
import apiUserContent from '@canvas/util/jquery/apiUserContent'
import {formatMessage, truncateText} from '@canvas/util/TextHelper'
import numberFormat from '@canvas/i18n/numberFormat'
import listFormatterPolyfill from '@canvas/util/listFormatter'
import '@canvas/datetime/jquery'
import '@canvas/jquery/jquery.instructure_misc_helpers'
import '@canvas/jquery/jquery.instructure_misc_plugins'

const I18n = useI18nScope('handlebars_helpers')

const listFormatter = Intl.ListFormat
  ? new Intl.ListFormat(ENV.LOCALE || navigator.language)
  : listFormatterPolyfill

const Handlebars = _Handlebars.default

const object = {
  t(...args1) {
    let key
    const adjustedLength = Math.max(args1.length, 1)
    const args = args1.slice(0, adjustedLength - 1)
    let options = args1[adjustedLength - 1]
    const wrappers = {}
    options =
      (options != null ? options.hash : undefined) != null
        ? options != null
          ? options.hash
          : undefined
        : {}
    for (key in options) {
      const value = options[key]
      if (key.match(/^w\d+$/)) {
        wrappers[new Array(parseInt(key.replace('w', ''), 10) + 2).join('*')] = value
        delete options[key]
      }
    }
    if (wrappers['*']) {
      options.wrapper = wrappers
    }
    if (typeof this !== 'undefined' && !(this instanceof Window)) {
      for (key of Array.from(this)) {
        options[key] = this[key]
      }
    }
    if (options.i18n_scope) {
      // eslint-disable-next-line react-hooks/rules-of-hooks
      useI18nScope(options.i18n_scope)
    }
    return new Handlebars.SafeString(htmlEscape(I18nObj.t(...Array.from(args), options)))
  },

  __i18nliner_escape(val) {
    return htmlEscape(val)
  },

  __i18nliner_safe(val) {
    return new htmlEscape.SafeString(val)
  },

  __i18nliner_concat(...args1) {
    const adjustedLength = Math.max(args1.length, 1)
    const args = args1.slice(0, adjustedLength - 1)
    return args.join('')
  },

  hiddenIf(condition) {
    if (condition) {
      return ' display:none; '
    }
  },

  hiddenUnless(condition) {
    if (!condition) {
      return ' display:none; '
    }
  },

  hiddenIfExists(condition) {
    if (condition != null) {
      return ' display:none; '
    }
  },

  hiddenUnlessExists(condition) {
    if (condition == null) {
      return ' display:none; '
    }
  },

  ifExists(condition, options) {
    if (condition != null) {
      return options.fn(this)
    } else {
      return options.inverse(this)
    }
  },

  semanticDateRange() {
    return new Handlebars.SafeString(semanticDateRange(...arguments))
  },

  // expects: a Date object or an ISO string
  contextSensitiveDatetimeTitle(datetime, {hash: {justText}}) {
    const localDatetime = $.datetimeString(datetime)
    let titleText = localDatetime
    if (ENV && ENV.CONTEXT_TIMEZONE && ENV.TIMEZONE !== ENV.CONTEXT_TIMEZONE) {
      const localText = I18n.t('#helpers.local', 'Local')
      const courseText = I18n.t('#helpers.course', 'Course')
      const courseDatetime = $.datetimeString(datetime, {timezone: ENV.CONTEXT_TIMEZONE})
      if (localDatetime !== courseDatetime) {
        titleText = `${htmlEscape(localText)}: ${htmlEscape(localDatetime)}<br>${htmlEscape(
          courseText
        )}: ${htmlEscape(courseDatetime)}`
      }
    }

    if (justText) {
      return new Handlebars.SafeString(titleText)
    } else {
      return new Handlebars.SafeString(
        `data-tooltip data-html-tooltip-title=\"${htmlEscape(titleText)}\"`
      )
    }
  },

  // expects: a Date object or an ISO string
  friendlyDatetime(datetime, {hash: {pubdate, contextSensitive}}) {
    if (datetime == null) {
      return
    }
    if (!isDate(datetime)) {
      datetime = tz.parse(datetime)
    }
    const fudged = $.fudgeDateForProfileTimezone(tz.parse(datetime))
    let timeTitleHtml = ''
    if (contextSensitive && ENV && ENV.CONTEXT_TIMEZONE) {
      timeTitleHtml = Handlebars.helpers.contextSensitiveDatetimeTitle(datetime, {
        hash: {justText: true},
      })
    } else {
      timeTitleHtml = $.datetimeString(datetime)
    }

    return new Handlebars.SafeString(`\
<time data-tooltip data-html-tooltip-title='${htmlEscape(
      timeTitleHtml
    )}' datetime='${datetime.toISOString()}' ${raw(pubdate ? 'pubdate' : undefined)}>
  <span aria-hidden='true'>${$.friendlyDatetime(fudged)}</span>
  <span class='screenreader-only'>${timeTitleHtml}</span>
</time>\
`)
  },

  fudge(datetime) {
    return $.fudgeDateForProfileTimezone(datetime)
  },

  unfudge(datetime) {
    return $.unfudgeDateForProfileTimezone(datetime)
  },

  // expects: a Date object or an ISO string
  formattedDate(datetime, format, {hash: {pubdate}}) {
    if (datetime == null) {
      return
    }
    if (!isDate(datetime)) {
      datetime = tz.parse(datetime)
    }
    return new Handlebars.SafeString(
      `<time data-tooltip title='${$.datetimeString(
        datetime
      )}' datetime='${datetime.toISOString()}' ${raw(pubdate ? 'pubdate' : undefined)}>${htmlEscape(
        datetime.toString(format)
      )}</time>`
    )
  },

  // IMPORTANT: these next two handlebars helpers emit profile-timezone
  // human-formatted strings. don't send them as is to the server (you can
  // parse them with tz.parse(), or preferably not use these values at all
  // when sending to the server, instead using a machine-formatted value
  // stored elsewhere).

  // expects: anything that $.datetimeString can handle
  datetimeFormatted(datetime, options) {
    return $.datetimeString(datetime, options != null ? options.hash : undefined)
  },

  datetimeFormattedWithTz(datetime) {
    const date = tz.parse(datetime)
    return tz.format(date, 'date.formats.full')
  },

  // Strips the time information from the datetime and accounts for the user's
  // timezone preference. expects: anything tz() can handle
  dateString(datetime) {
    if (!datetime) {
      return ''
    }
    return I18nObj.l('date.formats.medium', datetime)
  },

  // Convert the total amount of minutes into a Hours:Minutes format.
  minutesToHM(minutes) {
    const hours = Math.floor(minutes / 60)
    const real_minutes = minutes % 60
    const real_min_str = real_minutes < 10 ? '0' + real_minutes : real_minutes
    return `${hours}:${real_min_str}`
  },

  /**
   * Convert the total amount of minutes into a readable duration.
   * @param {number}  Duration in minutes elapsed
   * @return {string} String containing a formatted duration including hours and minutes
   * Example:
   *     ...
   *     duration = 97
   *     durationToString(duration)
   *     ...
   *     Returns
   *       "Duration: 1 hour and 37 minutes"
   */
  durationToString(duration) {
    // stores the hours in the duration
    const hours = Math.floor(duration / 60)
    // stores the remaining minutes after substracting the hours
    const minutes = duration % 60
    if (hours > 0) {
      return I18n.t('Duration: %{hours} hours and %{minutes} minutes', {hours, minutes})
    } else if (minutes > 1) {
      return I18n.t('Duration: %{minutes} minutes', {minutes})
    } else {
      return I18n.t('Duration: 1 minute')
    }
  },

  // helper for easily creating icon font markup
  addIcon(icontype) {
    return new Handlebars.SafeString(
      `<i role='presentation' class='icon-${htmlEscape(icontype)}'></i>`
    )
  },

  // helper for using date.js's custom toString method on Date objects
  dateToString(date, format) {
    if (date == null) {
      date = ''
    }
    return date.toString(format)
  },

  // convert a date to a string, using the given i18n format in the date.formats namespace
  tDateToString(date, i18n_format) {
    if (date == null) {
      date = ''
    }
    if (!date) {
      return ''
    }
    if (!isDate(date)) {
      date = tz.parse(date)
    }
    const fudged = $.fudgeDateForProfileTimezone(tz.parse(date))
    return I18nObj.l(`date.formats.${i18n_format}`, fudged)
  },

  // convert a date to a time string, using the given i18n format in the time.formats namespace
  tTimeToString(date, i18n_format) {
    if (date == null) {
      date = ''
    }
    if (!date) {
      return ''
    }
    if (!isDate(date)) {
      date = tz.parse(date)
    }
    const fudged = $.fudgeDateForProfileTimezone(tz.parse(date))
    return I18nObj.l(`time.formats.${i18n_format}`, fudged)
  },

  tTimeHours(date) {
    if (date == null) {
      date = ''
    }
    if (date.getMinutes() === 0 && date.getSeconds() === 0) {
      return I18nObj.l('time.formats.tiny_on_the_hour', date)
    } else {
      return I18nObj.l('time.formats.tiny', date)
    }
  },

  // convert an event date and time to a string using the given date and time format specifiers
  tEventToString(date, i18n_date_format, i18n_time_format) {
    if (date == null) {
      date = ''
    }
    if (i18n_date_format == null) {
      i18n_date_format = 'short'
    }
    if (i18n_time_format == null) {
      i18n_time_format = 'tiny'
    }
    if (date) {
      return I18nObj.t('time.event', {
        defaultValue: '%{date} at %{time}',
        date: I18nObj.l(`date.formats.${i18n_date_format}`, date),
        time: I18nObj.l(`time.formats.${i18n_time_format}`, date),
      })
    }
  },

  // formats a date as a string, using the given i18n format string
  strftime(date, fmtstr) {
    if (date == null) {
      date = ''
    }
    return I18nObj.strftime(date, fmtstr)
  },

  // outputs the format preferred for date inputs to prompt KB and SR
  // users with for interacting with datepickers
  //
  // @public
  //
  // @param {string} format defaults to 'datetime', if 'date' only returns
  //   the date portion of the format, same for 'time'
  //
  // @returns {String} the format to include for all datepickers
  accessibleDateFormat(format) {
    if (format == null) {
      format = 'datetime'
    }
    if (format === 'date') {
      return I18n.t('#helpers.accessible_date_only_format', 'YYYY-MM-DD')
    } else if (format === 'time') {
      return I18n.t('#helpers.accessible_time_only_format', 'hh:mm')
    } else {
      return I18n.t('#helpers.accessible_date_format', 'YYYY-MM-DD hh:mm')
    }
  },

  // outputs the prompt to include in labels attached to date pickers for
  // screenreader consumption
  //
  // @public
  //
  // @param {string} format defaults to 'datetime', if 'date' only returns
  //   the date portion of the format, same for 'time'
  //
  // @returns {String} the prompt for telling SRs about how to
  //   input a date
  datepickerScreenreaderPrompt(format) {
    if (format == null) {
      format = 'datetime'
    }
    const promptText = I18n.t('#helpers.accessible_date_prompt', 'Format Like')
    format = Handlebars.helpers.accessibleDateFormat(format)
    return `${promptText} ${format}`
  },

  mimeClass,

  // use this method to process any user content fields returned in api responses
  // this is important to handle object/embed tags safely, and to properly display audio/video tags
  convertApiUserContent(html, {hash}) {
    let content = apiUserContent.convert(html, hash)
    // if the content is going to get picked up by tinymce, do not mark as safe
    // because we WANT it to be escaped again.
    if (!hash || !hash.forEditing) {
      content = new Handlebars.SafeString(content)
    }
    return content
  },

  // Turns plaintext into HTML with links and newlines
  // Not for use by text in an RCE
  linkify(text) {
    const html = formatMessage(text)
    const content = new Handlebars.SafeString(html)
    return content
  },

  newlinesToBreak(string) {
    // Convert a null to an empty string so it doesn't blow up.
    if (!string) {
      string = ''
    }
    return new Handlebars.SafeString(htmlEscape(string).replace(/\n/g, '<br />'))
  },

  not(arg) {
    return !arg
  },

  // runs block if all arguments are === to each other
  // usage:
  // {{#ifEqual argument1 argument2 'a string argument' argument4}}
  //   everything was equal
  // {{else}}
  //   everything was NOT equal
  // {{/ifEqual}}
  ifEqual() {
    let previousArg = arguments[0]
    const adjustedLength = Math.max(arguments.length, 2)
    const args = Array.from(arguments).slice(1, adjustedLength - 1)
    const {fn, inverse} = arguments[adjustedLength - 1]
    for (const arg of Array.from(args)) {
      if (arg !== previousArg) {
        return inverse(this)
      }
      previousArg = arg
    }
    return fn(this)
  },

  // runs block if *ALL* arguments are truthy
  // usage:
  // {{#ifAll arg1 arg2 arg3 arg}}
  //   everything was truthy
  // {{else}}
  //   something was falsey
  // {{/ifAll}}
  ifAll() {
    const adjustedLength = Math.max(arguments.length, 1),
      args = Array.from(arguments).slice(0, adjustedLength - 1),
      {fn, inverse} = arguments[adjustedLength - 1]
    for (const arg of Array.from(args)) {
      if (!arg) {
        return inverse(this)
      }
    }
    return fn(this)
  },

  // runs block if *ANY* arguments are truthy
  // usage:
  // {{#ifAny arg1 arg2 arg3 arg}}
  //   something was truthy
  // {{else}}
  //   all were falsy
  // {{/ifAny}}
  ifAny() {
    const adjustedLength = Math.max(arguments.length, 1),
      args = Array.from(arguments).slice(0, adjustedLength - 1),
      {fn, inverse} = arguments[adjustedLength - 1]
    for (const arg of Array.from(args)) {
      if (arg) {
        return fn(this)
      }
    }
    return inverse(this)
  },

  // runs block if the argument is null or undefined
  // usage:
  // {{#ifNull arg}}
  //   arg was null
  // {{else}}
  //   arg is not null
  // {{/ifNull}}
  ifNull() {
    const adjustedLength = Math.max(arguments.length, 1),
      args = Array.from(arguments).slice(0, adjustedLength - 1),
      {fn, inverse} = arguments[adjustedLength - 1]
    const arg = args[0]
    if (arg != null) {
      return inverse(this)
    }
    return fn(this)
  },

  // {{#eachWithIndex records startingIndex=0}}
  //   <li class="legend_item{{_index}}"><span></span>{{Name}}</li>
  // {{/each_with_index}}
  //
  // (startingIndex will default to 0 if not specified)
  eachWithIndex(context, options) {
    const {fn} = options
    const {inverse} = options
    const startingValue = parseInt(options.hash.startingValue || 0, 10)
    let ret = ''

    if (context && context.length > 0) {
      for (const index of Object.keys(context || {})) {
        const ctx = context[index]
        ctx._index = parseInt(index, 10) + startingValue
        ret += fn(ctx)
      }
    } else {
      ret = inverse(this)
    }

    return ret
  },

  // loop through an object's properties, exposing "property" and
  // "value."
  //
  // ex.
  //
  // obj =
  //   group_one: [
  //     { label: 'one', val: 1 }
  //     { label: 'two', val: 2 }
  //   ],
  //   group_two: [
  //     { label: 'three', val: 3 }
  //     { label: 'four', val: 4 }
  //   ]
  //
  // {{#eachProp this}}
  //   <optgroup label="{{property}}">
  //     {{#each this.value}}
  //       <option value="{{val}}">{{label}}</option>
  //     {{/each}}
  //   </optgroup>
  // {{/each}}
  //
  // outputs:
  // <optgroup label="group_one">
  //   <option value="1">one</option>
  //   <option value="2">two</option>
  // </optgroup>
  // <optgroup label="group_two">
  //   <option value="3">three</option>
  //   <option value="4">four</option>
  // </optgroup>
  //
  eachProp(context, options) {
    return (() => {
      const result = []
      for (const prop in context) {
        result.push(options.fn({property: prop, value: context[prop]}))
      }
      return result
    })().join('')
  },

  // runs block if the setting is set to the value
  // usage:
  // {{#ifSettingIs some_setting some_value}}
  //   The setting is set to the thing!
  // {{else}}
  //   The setting is set to something else or doesn't exist
  // {{/ifSettingIs}}
  ifSettingIs() {
    const [setting, value, {fn, inverse}] = Array.from(arguments)
    const settings = ENV.SETTINGS
    if (settings[setting] === value) {
      return fn(this)
    }
    return inverse(this)
  },

  // evaluates the block for each item in context and passes the result to list formatter
  toSentence(context, options) {
    const results = map(context, c => options.fn(c))
    return listFormatter.format(results)
  },

  dateSelect(name, options) {
    return new Handlebars.SafeString(dateSelect(name, options.hash).html())
  },

  // usage:
  //   if 'this' is {human: true}
  //   and you do: {{checkbox "human"}}
  //   you'll get: <input name="human" type="hidden" value="0" />
  //               <input type="checkbox"
  //                      value="1"
  //                      id="human"
  //                      checked="true"
  //                      name="human" >
  // you can pass custom attributes and use nested properties:
  //   if 'this' is {likes: {tacos: true}}
  //   and you do: {{checkbox "likes.tacos" class="foo bar"}}
  //   you'll get: <input name="likes[tacos]" type="hidden" value="0" />
  //               <input type="checkbox"
  //                      value="1"
  //                      id="likes_tacos"
  //                      checked="true"
  //                      name="likes[tacos]"
  //                      class="foo bar" >
  // you can append a unique string to the id with uniqid:
  //   if you pass id=someid" and uniqid=true as parameters
  //   the result is like doing id="someid-{{uniqid}}" inside a manually
  //   created input tag.
  checkbox(propertyName, {hash}) {
    let key
    const splitPropertyName = propertyName.split(/\./)
    const snakeCase = splitPropertyName.join('_')

    if (hash.prefix) {
      splitPropertyName.unshift(hash.prefix)
      delete hash.prefix
    }

    const bracketNotation =
      splitPropertyName[0] +
      chain(splitPropertyName)
        .drop()
        .map(prop => `[${prop}]`)
        .value()
        .join('')
    const inputProps = {
      type: 'checkbox',
      value: 1,
      id: snakeCase,
      name: bracketNotation,
      ...hash,
    }

    if (inputProps.checked == null) {
      const value = reduce(
        splitPropertyName,
        function (memo, key_) {
          if (memo != null) {
            return memo[key_]
          }
        },
        this
      )
      if (value) {
        inputProps.checked = true
      }
    }

    if ('aria-expanded' in inputProps) {
      inputProps['aria-expanded'] = inputProps['aria-expanded'] ? 'true' : 'false'
    }

    for (const prop of ['checked', 'disabled']) {
      if (inputProps[prop]) {
        inputProps[prop] = prop
      } else {
        delete inputProps[prop]
      }
    }

    if (inputProps.uniqid && inputProps.id) {
      inputProps.id += `-${Handlebars.helpers.uniqid.call(this)}`
    }
    delete inputProps.uniqid

    const attributes = (() => {
      const result = []
      for (key in inputProps) {
        const val = inputProps[key]
        if (val != null) {
          result.push(`${htmlEscape(key)}=\"${htmlEscape(val)}\"`)
        }
      }
      return result
    })()

    const hiddenDisabledHtml = inputProps.disabled ? 'disabled' : ''

    return new Handlebars.SafeString(`\
<input name="${htmlEscape(inputProps.name)}" type="hidden" value="0" ${hiddenDisabledHtml}>
<input ${raw(attributes.join(' '))} />\
`)
  },

  toPercentage(number) {
    return parseInt(100 * number, 10) + '%'
  },

  toPrecision(number, precision) {
    if (number) {
      return parseFloat(number).toPrecision(precision)
    } else {
      return ''
    }
  },

  checkedIf(thing, thingToCompare, _hash) {
    if (arguments.length === 3) {
      if (thing === thingToCompare) {
        return 'checked'
      } else {
        return ''
      }
    } else if (thing) {
      return 'checked'
    } else {
      return ''
    }
  },

  checkedIfNullOrUndef(thing) {
    if (thing === null || thing === undefined) {
      return 'checked'
    } else {
      return ''
    }
  },

  fullWidthIf(condition) {
    if (condition) {
      return ' width: 100%; '
    }
  },

  selectedIf(thing, thingToCompare, _hash) {
    if (arguments.length === 3) {
      if (thing === thingToCompare) {
        return 'selected'
      } else {
        return ''
      }
    } else if (thing) {
      return 'selected'
    } else {
      return ''
    }
  },

  disabledIf(thing, _hash) {
    if (thing) {
      return 'disabled'
    } else {
      return ''
    }
  },

  readonlyIf(thing, _hash) {
    if (thing) {
      return 'readonly'
    } else {
      return ''
    }
  },

  checkedUnless(thing) {
    if (thing) {
      return ''
    } else {
      return 'checked'
    }
  },

  join(array, separator, _hash) {
    if (separator == null) {
      separator = ','
    }
    if (!array) {
      return ''
    }
    return array.join(separator)
  },

  ifIncludes(array, thing, options) {
    if (!array) {
      return false
    }
    if (Array.from(array).includes(thing)) {
      return options.fn(this)
    } else {
      return options.inverse(this)
    }
  },

  disabledIfIncludes(array, thing) {
    if (!array) {
      return ''
    }
    if (Array.from(array).includes(thing)) {
      return 'disabled'
    } else {
      return ''
    }
  },
  truncate_left(string, max) {
    return Handlebars.Utils.escapeExpression(
      truncateText(string.split('').reverse().join(''), {max}).split('').reverse().join('')
    )
  },

  truncate(string, max) {
    return Handlebars.Utils.escapeExpression(truncateText(string, {max}))
  },

  escape_html(string) {
    return htmlEscape(string)
  },

  enrollmentName,

  // Public: Print an array as a comma-separated list.
  //
  // separator - The string to separate values with (default: ', ')
  // propName - If array elements are objects, this is the object property
  //            that should be printed (default: null).
  // limit - Only display the first n results of the list, following by "end." (default: null)
  // end - If the list is truncated, display this string at the end of the list (default: '...').
  //
  // Examples
  //   values = [1,2,3]
  //   complexValues = [{ id: 1 }, { id: 2 }, { id: 3 }]
  //   {{list values}} #=> 1, 2, 3
  //   {{list values separator=";"}} #=> 1;2;3
  //   {{list complexValues propName="id"}} #=> 1, 2, 3
  //   {{list values limit=2}} #=> 1, 2...
  //   {{list values limit=2 end="!"}} #=> 1, 2!
  //
  // Returns a string.
  list(value, options) {
    defaults(options.hash, {separator: ', ', propName: null, limit: null, end: '...'})
    const {propName, limit, end, separator} = options.hash
    let result = map(value, function (item) {
      if (propName) {
        return item[propName]
      } else {
        return item
      }
    })
    if (limit) {
      result = result.slice(0, limit)
    }
    const string = result.join(separator)
    if (limit && value.length > limit) {
      return `${string}${end}`
    } else {
      return string
    }
  },

  titleize(str) {
    if (typeof str !== 'string') return ''
    const words = str.split(/[ _]+/)
    const titleizedWords = words.map(w => w[0].toUpperCase() + w.slice(1))
    return titleizedWords.join(' ')
  },

  uniqid(context) {
    if (arguments.length <= 1) {
      context = this || window
    }
    if (!context._uniqid_) {
      const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
      context._uniqid_ = [1, 2, 3, 4, 5, 6, 7, 8]
        .map(_i => chars.charAt(Math.floor(Math.random() * chars.length)))
        .join('')
    }
    return context._uniqid_
  },

  // Public: Render a child Backbone view.
  //
  // backboneView - A class that extends from Backbone.View.
  //
  // Examples
  //   childView = Backbone.View.extend(...)
  //
  //   {{view childView}}
  //
  // Returns the child view's HTML.
  view(backboneView) {
    const onNextFrame = fn => (window.requestAnimationFrame || setTimeout)(fn, 0)
    const id = `placeholder-${$.guid++}`
    const replace = function () {
      const $span = $(`#${id}`)
      if ($span.length) {
        return $span.replaceWith(backboneView.$el)
      } else {
        return onNextFrame(replace)
      }
    }

    backboneView.render()
    onNextFrame(replace)
    return new Handlebars.SafeString(`<span id=\"${id}\">pk</span>`)
  },

  // Public: yields the first non-nil argument
  //
  // Examples
  //   Name: {{or display_name short_name 'Unknown'}}
  //
  // Returns the first non-null argument or null
  or(...args1) {
    const adjustedLength = Math.max(args1.length, 1)
    const args = args1.slice(0, adjustedLength - 1)
    for (const arg of Array.from(args)) {
      if (arg) {
        return arg
      }
    }
  },

  // Public: returns icon for outcome mastery level
  addMasteryIcon(status, options) {
    if (options == null) {
      options = {}
    }
    const iconType =
      {
        exceeds: 'check-plus',
        mastery: 'check',
        near: 'plus',
      }[status] || 'x'
    return new Handlebars.SafeString(
      `<i aria-hidden='true' class='icon-${htmlEscape(iconType)}'></i>`
    )
  },

  // Public: Render `fn` or `inverse` depending on whether firstArg is greater than secondArg
  ifGreaterThan(x, y, options) {
    if (x > y) {
      return options.fn(this)
    } else {
      return options.inverse(this)
    }
  },

  n(number, {hash: {precision, percentage, strip_insignificant_zeros}}) {
    return I18nObj.n(number, {precision, percentage, strip_insignificant_zeros})
  },

  nf(number, {hash: {format}}) {
    return numberFormat[format](number)
  },

  // Public: look up an element of a hash or array
  lookup(obj, key) {
    return obj && obj[key]
  },
}
for (const name in object) {
  const fn = object[name]
  Handlebars.registerHelper(name, fn)
}
export default Handlebars
