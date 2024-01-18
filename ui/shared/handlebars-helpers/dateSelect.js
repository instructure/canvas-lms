//
// Copyright (C) 2012 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import I18n from '@canvas/i18n'
import $ from 'jquery'
import h from '@instructure/html-escape'
import {clone, defaults} from 'lodash'

/*
xsslint safeString.identifier i
*/

const builders = {
  year(options, htmlOptions) {
    const step = options.startYear < options.endYear ? 1 : -1
    const $result = $('<select />', htmlOptions)
    if (options.includeBlank) $result.append('<option />')
    let i = options.startYear
    while (i * step <= options.endYear * step) {
      i += step
      $result.append($(`<option value="${i}">${i}</option>`))
    }
    return $result
  },
  month(options, htmlOptions) {
    const months = I18n.lookup('date.month_names')
    const $result = $('<select />', htmlOptions)
    if (options.includeBlank) $result.append('<option />')
    for (let i = 1; i <= 12; i++) {
      $result.append($(`<option value="${i}">${h(months[i])}</option>`))
    }
    return $result
  },
  day(options, htmlOptions) {
    const $result = $('<select />', htmlOptions)
    if (options.includeBlank) $result.append('<option />')
    for (let i = 1; i <= 31; i++) {
      $result.append($(`<option value="${i}">${i}</option>`))
    }
    return $result
  },
}

// generates something like rails' date_select/select_date
// TODO: feature parity
export default function dateSelect(name, options, htmlOptions = clone(options)) {
  const validOptions = ['type', 'startYear', 'endYear', 'includeBlank', 'order']
  validOptions.forEach(opt => delete htmlOptions[opt])

  if (htmlOptions.class == null) htmlOptions.class = ''
  htmlOptions.class += ' date-select'

  const year = new Date().getFullYear()
  const position = {
    year: 1,
    month: 2,
    day: 3,
  }

  const order = I18n.lookup('date.order', {
    defaultValue: ['year', 'month', 'day'],
  })

  if (options.type === 'birthdate') {
    defaults(options, {
      startYear: year - 1,
      endYear: year - 125,
      includeBlank: true,
    })
  }

  defaults(options, {
    startYear: year - 5,
    endYear: year + 5,
    order,
  })

  const $result = $('<span>')
  // in coffeescript: for i in [0...options.order.length]
  for (
    let i = 0, end = options.order.length, asc = end >= 0;
    asc ? i < end : i > end;
    asc ? i++ : i--
  ) {
    const type = options.order[i]
    const tName = name.replace(/(\]?)$/, `(${position[type]}i)$1`)
    const html = builders[type](options, {name: tName, ...htmlOptions})
    $result.append(html)
    delete htmlOptions.id
  }
  return $result
}
