#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'i18n!instructure',
  'jquery'
  'underscore',
  'str/htmlEscape'
], (I18n, $, _, h) ->

  ###
  xsslint safeString.identifier i
  ###

  builders =
    year: (options, htmlOptions) ->
      step = if options.startYear < options.endYear then 1 else -1
      $result = $('<select />', htmlOptions)
      $result.append('<option />') if options.includeBlank
      i = options.startYear
      while i*step <= options.endYear*step
        i += step
        $result.append($('<option value="' + i + '">' + i + '</option>'))
      $result
    month: (options, htmlOptions, dateSettings) ->
      months = dateSettings.month_names
      $result = $('<select />', htmlOptions)
      $result.append('<option />') if options.includeBlank
      for i in [1..12]
        $result.append($('<option value="' + i + '">' + h(months[i]) + '</option>'))
      $result
    day: (options, htmlOptions) ->
      $result = $('<select />', htmlOptions)
      $result.append('<option />') if options.includeBlank
      for i in [1..31]
        $result.append($('<option value="' + i + '">' + i + '</option>'))
      $result

  # generates something like rails' date_select/select_date
  # TODO: feature parity
  dateSelect = (name, options, htmlOptions = _.clone(options)) ->
    validOptions = ['type', 'startYear', 'endYear', 'includeBlank', 'order']
    delete htmlOptions[opt] for opt in validOptions
    htmlOptions['class'] ?= ''
    htmlOptions['class'] += ' date-select'

    year         = (new Date()).getFullYear()
    position     = {year: 1, month: 2, day: 3}
    dateSettings = I18n.lookup('date')

    if options.type is 'birthdate'
      _.defaults options,
        startYear:    year - 1
        endYear:      year - 125
        includeBlank: true

    _.defaults options,
      startYear: year - 5
      endYear:   year + 5
      order:     dateSettings.order || ['year', 'month', 'day']

    $result = $('<span>')
    for i in [0...options.order.length]
      type = options.order[i]
      tName = name.replace(/(\]?)$/, "(" + position[type] + "i)$1")
      html = builders[type](
        options,
        _.extend({name: tName}, htmlOptions),
        dateSettings
      )
      $result.append(html)
      delete htmlOptions.id
    $result
