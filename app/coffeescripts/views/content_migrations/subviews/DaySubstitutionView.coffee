#
# Copyright (C) 2013 - present Instructure, Inc.
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

import _ from 'underscore'
import $ from 'jquery'
import Backbone from 'Backbone'
import I18n from 'i18nObj'
import template from 'jst/content_migrations/subviews/DaySubstitution'

export default class DaySubstitutionView extends Backbone.View
  template: template

  els:
    ".currentDay" : "$currentDay"
    ".subDay"     : "$subDay"

  events:
    'click a'             : 'removeView'
    'change .currentDay'  : 'changeCurrentDay'
    'change .subDay'      : 'updateModelData'

  # When a new view is created, make sure the model is updated
  # with it's initial attributes/values

  afterRender: -> @updateModelData()

  # Ensure that after you update the current day you change focus
  # to the next select box. In this case the next select box is
  # @$subDay

  changeCurrentDay: ->
    @updateModelData()
    #@$subDay.focus()

  # Clear the model and add new value and key
  # for the day representation.
  #
  # @api private

  updateModelData: ->
    sub_data = {}
    sub_data[@$currentDay.val()] = @$subDay.val()
    @updateName()

    @model.clear()
    @model.set sub_data

  updateName: ->
    @$subDay.attr 'name', "date_shift_options[day_substitutions][#{@$currentDay.val()}]"

  # Remove the model from both the view and
  # the collection it belongs to.
  #
  # @api private

  removeView: (event) ->
    event.preventDefault()
    @model.collection.remove @model

  # Add weekdays to the handlebars template
  #
  # @api backbone override

  toJSON: ->
    json = super
    json.weekdays = @weekdays()
    json

  # Return an array of objects with weekdays
  # ie:
  #   [{index: 0, name: 'Sunday'}, {index: 1, name: 'Monday'}]
  # @api private

  weekdays: ->
    dayArray = I18n.lookup('date.day_names')
    _.map dayArray, (day) => {index: _.indexOf(dayArray, day), name: day}
