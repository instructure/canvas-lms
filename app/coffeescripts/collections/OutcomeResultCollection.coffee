#
# Copyright (C) 2015 - present Instructure, Inc.
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
  'jquery'
  'underscore'
  'Backbone'
  'compiled/models/grade_summary/Outcome'
  'compiled/collections/WrappedCollection'
], ($, _, Backbone, Outcome, WrappedCollection) ->
  class OutcomeResultCollection extends WrappedCollection
    key: 'outcome_results'
    model: Outcome
    @optionProperty 'outcome'
    url: -> "/api/v1/courses/#{@course_id}/outcome_results?user_ids[]=#{@user_id}&outcome_ids[]=#{@outcome.id}&include[]=alignments&per_page=100"
    loadAll: true

    comparator: (model) ->
      return -1 * model.get('submitted_or_assessed_at').getTime()

    initialize: ->
      super
      @model = Outcome.extend defaults: {
        points_possible: @outcome.get('points_possible'),
        mastery_points: @outcome.get('mastery_points')
      }
      @course_id = ENV.context_asset_string?.replace('course_', '')
      @user_id = ENV.student_id
      @on('reset', @handleReset)
      @on('add', @handleAdd)

    handleReset: =>
      @each @handleAdd

    handleAdd: (model) =>
      alignment_id = model.get('links').alignment
      model.set('alignment_name', @alignments.get(alignment_id)?.get('name'))

    parse: (response) ->
      @alignments ?= new Backbone.Collection([])
      @alignments.add(response?.linked?.alignments || [])
      response[@key]
