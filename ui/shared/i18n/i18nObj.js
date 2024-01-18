/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import 'date-js'
import i18nLolcalize from './i18nLolcalize'
import I18n from 'i18n-js'
import {
  extend as activateI18nliner,
  inferKey,
  normalizeDefault,
} from '@instructure/i18nliner-runtime'
import logEagerLookupViolations from './logEagerLookupViolations'
import htmlEscape from '@instructure/html-escape'

activateI18nliner(I18n, {
  // this is what we use elsewhere in canvas, so make i18nliner use it too
  HtmlSafeString: htmlEscape.SafeString,

  // handle our absolute keys
  keyPattern: /^\#?\w+(\.\w+)+$/,

  inferKey: (defaultValue, translateOptions) => `#${inferKey(defaultValue, translateOptions)}`,

  // when inferring the key at runtime (i.e. js/coffee or inline hbs `t`
  // call), signal to normalizeKey that it shouldn't be scoped.
  normalizeKey: (key, options) => {
    if (key[0] === '#') {
      return key.slice(1)
    } else if (options.scope) {
      return `${options.scope}.${key}`
    } else {
      return key
    }
  },

  normalizeDefault: window.ENV && window.ENV.lolcalize ? i18nLolcalize : normalizeDefault,
})

/*
 * Overridden interpolator that localizes any interpolated numbers.
 * Defaults to localizeNumber behavior (precision 9, but strips
 * insignificant digits). If you want a different format, do it
 * before you interpolate.
 */
const interpolate = I18n.interpolate.bind(I18n)

I18n.interpolate = function (message, origOptions) {
  const options = {...origOptions}
  const matches = message.match(I18n.placeholder) || []

  matches.forEach(placeholder => {
    const name = placeholder.replace(I18n.placeholder, '$1')
    if (typeof options[name] === 'number') {
      options[name] = this.localizeNumber(options[name])
    }
  })
  return interpolate(message, options)
}

I18n.locale = document.documentElement.getAttribute('lang')

I18n.lookup = logEagerLookupViolations(function (key, options = {}) {
  const locale = options.locale || I18n.currentLocale()
  const localeTranslations = I18n.translations[locale] || {}
  return localeTranslations[key] || options.defaultValue || null
})

const _localize = I18n.localize.bind(I18n)
I18n.localize = function (scope, value) {
  let result = _localize.call(this, scope, value)
  if (scope.match(/^(date|time)/)) result = result.replace(/\s{2,}/, ' ')
  return result
}

I18n.n = I18n.localizeNumber = (value, options = {}) => {
  const format = {
    delimiter: I18n.lookup('number.format.delimiter'),
    separator: I18n.lookup('number.format.separator'),
    // use a high precision and strip zeros if no precision is provided
    // 5 is as high as we want to go without causing precision issues
    // when used with toFixed() and large numbers
    strip_insignificant_zeros: options.strip_insignificant_zeros || options.precision == null,
    precision: options.precision != null ? options.precision : 5,
  }

  if (value && value.toString().match(/e/)) {
    return value.toString()
  } else if (options.percentage) {
    return I18n.toPercentage(value, format)
  } else {
    return I18n.toNumber(value, format)
  }
}

const padding = (n, pad = '00', len = 2) => {
  const s = pad + n.toString()
  return s.substr(s.length - len)
}

I18n.strftime = function (date, format) {
  const options = {
    abbr_day_names: I18n.lookup('date.abbr_day_names'),
    abbr_month_names: I18n.lookup('date.abbr_month_names'),
    day_names: I18n.lookup('date.day_names'),
    meridian: I18n.lookup('date.meridian', {defaultValue: ['AM', 'PM']}),
    month_names: I18n.lookup('date.month_names'),
  }

  const weekDay = date.getDay()
  const day = date.getDate()
  const year = date.getFullYear()
  const month = date.getMonth() + 1
  const dayOfYear =
    1 + Math.round((new Date(year, month - 1, day) - new Date(year, 0, 1)) / 86400000)
  const hour = date.getHours()
  let hour12 = hour
  const meridian = hour > 11 ? 1 : 0
  const secs = date.getSeconds()
  const mils = date.getMilliseconds()
  const mins = date.getMinutes()
  const offset = date.getTimezoneOffset()
  const epochOffset = Math.floor(date.getTime() / 1000)
  const absOffsetHours = Math.floor(Math.abs(offset / 60))
  const absOffsetMinutes = Math.abs(offset) - absOffsetHours * 60
  const timezoneoffset = `${offset > 0 ? '-' : '+'}${
    absOffsetHours.toString().length < 2 ? `0${absOffsetHours}` : absOffsetHours
  }${absOffsetMinutes.toString().length < 2 ? `0${absOffsetMinutes}` : absOffsetMinutes}`

  if (hour12 > 12) {
    hour12 -= 12
  } else if (hour12 === 0) {
    hour12 = 12
  }

  /*
    not implemented:
      %N  // nanoseconds
      %6N // microseconds
      %9N // nanoseconds
      %U  // week number of year, starting with the first Sunday as the first day of the 01st week (00..53)
      %V  // week number of year according to ISO 8601 (01..53) (week starts on Monday, week 01 is the one with the first Thursday of the year)
      %W  // week number of year, starting with the first Monday as the first day of the 01st week (00..53)
      %Z  // time zone name
  */
  let optionsNeeded = false
  const f = format
    .replace(
      /%([DFrRTv])/g,
      (str, p1) =>
        ({
          D: '%m/%d/%y',
          F: '%Y-%m-%d',
          r: '%I:%M:%S %p',
          R: '%H:%M',
          T: '%H:%M:%S',
          v: '%e-%b-%Y',
        }[p1])
    )
    .replace(/%(%|\-?[a-zA-Z]|3N)/g, (str, p1) => {
      // check to see if we need an options object
      switch (p1) {
        case 'a':
        case 'A':
        case 'b':
        case 'B':
        case 'h':
        case 'p':
        case 'P':
          if (options == null) {
            optionsNeeded = true
            return ''
          }
      }

      switch (p1) {
        case 'a':
          return options.abbr_day_names[weekDay]
        case 'A':
          return options.day_names[weekDay]
        case 'b':
          return options.abbr_month_names[month]
        case 'B':
          return options.month_names[month]
        case 'd':
          return padding(day)
        case '-d':
          return day
        case 'e':
          return padding(day, ' ')
        case 'h':
          return options.abbr_month_names[month]
        case 'H':
          return padding(hour)
        case '-H':
          return hour
        case 'I':
          return padding(hour12)
        case '-I':
          return hour12
        case 'j':
          return padding(dayOfYear, '00', 3)
        case 'k':
          return padding(hour, ' ')
        case 'l':
          return padding(hour12, ' ')
        case 'L':
          return padding(mils, '00', 3)
        case 'm':
          return padding(month)
        case '-m':
          return month
        case 'M':
          return padding(mins)
        case '-M':
          return mins
        case 'n':
          return '\n'
        case '3N':
          return padding(mils, '00', 3)
        case 'p':
          return options.meridian[meridian]
        case 'P':
          return options.meridian[meridian].toLowerCase()
        case 's':
          return epochOffset
        case 'S':
          return padding(secs)
        case '-S':
          return secs
        case 't':
          return '\t'
        case 'u':
          return weekDay || weekDay + 7
        case 'w':
          return weekDay
        case 'y':
          return padding(year)
        case '-y':
          return padding(year).replace(/^0+/, '')
        case 'Y':
          return year
        case 'z':
          return timezoneoffset
        case '%':
          return '%'
        default:
          return str
      }
    })

  if (optionsNeeded) {
    return date.toString()
  }
  return f
}

// like the original, except it formats count
I18n.pluralize = function (count, scope, options) {
  let translation

  try {
    translation = this.lookup(scope, options)
  } catch (error) {
    // no-op
  }

  if (!translation) {
    return this.missingTranslation(scope)
  }

  options = {precision: 0, ...options}
  options.count = this.localizeNumber(count, options)

  let message
  switch (Math.abs(count)) {
    case 0:
      message =
        translation.zero != null
          ? translation.zero
          : translation.none != null
          ? translation.none
          : translation.other != null
          ? translation.other
          : this.missingTranslation(scope, 'zero')
      break
    case 1:
      message = translation.one != null ? translation.one : this.missingTranslation(scope, 'one')
      break
    default:
      message =
        translation.other != null ? translation.other : this.missingTranslation(scope, 'other')
  }

  return this.interpolate(message, options)
}

class Scope {
  constructor(scope) {
    this.scope = scope
    this.cache = new Map()
  }

  translate(...args) {
    let cacheKey
    try {
      cacheKey = I18n.locale + JSON.stringify(args)
    } catch (e) {
      // if there is something in the arguments we can't stringify, just do it without cache
    }
    if (cacheKey) {
      const cached = this.cache.get(cacheKey)
      if (cached) {
        return cached
      } else {
        const valToCache = this.translateWithoutCache(...args)
        this.cache.set(cacheKey, valToCache)
        return valToCache
      }
    } else {
      return this.translateWithoutCache(...args)
    }
  }

  translateWithoutCache() {
    let args = arguments
    const options = args[args.length - 1]
    if (options instanceof Object) {
      options.scope = this.scope
    } else {
      args = [...args, {scope: this.scope}]
    }
    return I18n.translate(...args)
  }

  localize(key, date) {
    if (key[0] === '#') key = key.slice(1)
    return I18n.localize(key, date)
  }

  beforeLabel(text) {
    return this.t('#before_label_wrapper', '%{text}:', {text})
  }
}
I18n.scope = Scope

Scope.prototype.lookup = I18n.lookup.bind(I18n)
Scope.prototype.toTime = I18n.toTime.bind(I18n)
Scope.prototype.toNumber = I18n.toNumber.bind(I18n)
Scope.prototype.toCurrency = I18n.toCurrency.bind(I18n)
Scope.prototype.toHumanSize = I18n.toHumanSize.bind(I18n)
Scope.prototype.toPercentage = I18n.toPercentage.bind(I18n)
Scope.prototype.localizeNumber = I18n.n.bind(I18n)
Scope.prototype.currentLocale = I18n.currentLocale.bind(I18n)

// shorthand
Scope.prototype.t = Scope.prototype.translate
Scope.prototype.l = Scope.prototype.localize
Scope.prototype.n = Scope.prototype.localizeNumber
Scope.prototype.p = Scope.prototype.pluralize

export default I18n
export const useScope = scope => new Scope(scope)
export const useTranslations = (locale, translations) => {
  I18n.translations[locale] = I18n.translations[locale] || {}
  Object.assign(I18n.translations[locale], translations)
}
