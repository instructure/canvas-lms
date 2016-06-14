#
# Copyright (C) 2012 Instructure, Inc.
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
#

define [
  'i18n!outcomes'
  'underscore'
  'Backbone'
  'compiled/models/grade_summary/CalculationMethodContent'
], (I18n, _, Backbone, CalculationMethodContent) ->

  class Outcome extends Backbone.Model
    defaults:
      calculation_method: "decaying_average"
      calculation_int: 65
      mastery_points: 3
      points_possible: 5
      ratings: [
        description: I18n.t("criteria.exceeds_expectations", "Exceeds Expectations")
        points: 5
      ,
        description: I18n.t("criteria.meets_expectations", "Meets Expectations")
        points: 3
      ,
        description: I18n.t("criteria.does_not_meet_expectations", "Does Not Meet Expectations")
        points: 0
      ]

    defaultCalculiationInt: -> {
      n_mastery: 5
      decaying_average: 65
    }[@get('calculation_method')]

    initialize: ->
      @on 'change:calculation_method', (model, changedTo) =>
        model.set calculation_int: @defaultCalculiationInt()
      super

    calculationMethodContent: ->
      new CalculationMethodContent(@)

    calculationMethods: ->
      @calculationMethodContent().toJSON()

    name: ->
      @get 'title'

    isNative: ->
      @outcomeLink && (@get('context_id') == @outcomeLink.context_id && @get('context_type') == @outcomeLink.context_type)

    # The api returns abbreviated data by default
    # which in most cases means there's no description.
    # Run fetch() to get all the data.
    isAbbreviated: ->
      !@has('description')

    # overriding to work with both outcome and outcome link responses
    parse: (resp) ->
      if resp.outcome # it's an outcome link
        @outcomeLink = resp
        @outcomeGroup = resp.outcome_group
        resp.outcome
      else
        resp

    present: ->
      _.extend({}, @toJSON(), @calculationMethodContent().present())

    setUrlTo: (action) ->
      @url =
        switch action
          when 'add'    then @outcomeGroup.outcomes_url
          when 'edit'   then @get 'url'
          when 'delete' then @outcomeLink.url
