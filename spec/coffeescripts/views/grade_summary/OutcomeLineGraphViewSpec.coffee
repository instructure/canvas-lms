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
  'underscore'
  'compiled/models/grade_summary/Outcome'
  'compiled/collections/OutcomeResultCollection'
  'compiled/views/grade_summary/OutcomeLineGraphView'
  'timezone'
  'helpers/fakeENV'
], (_, Outcome, OutcomeResultCollection, OutcomeLineGraphView, tz, fakeENV) ->

  QUnit.module 'OutcomeLineGraphViewSpec',
    setup: ->
      fakeENV.setup()
      ENV.context_asset_string = 'course_1'
      ENV.current_user = {display_name: 'Student One'}
      ENV.student_id = 6

      @server = sinon.fakeServer.create()
      @response = {
        outcome_results: [{
          submitted_or_assessed_at: tz.parse('2015-04-24T19:27:54Z')
          links: {
            alignment: 'alignment_1'
          }
        }],
        linked: {
          alignments: [{
            id: 'alignment_1'
            name: 'Alignment Name'
          }]
        }
      }

      @outcomeLineGraphView = new OutcomeLineGraphView({
        el: $('<div class="line-graph"></div>')[0]
        model: new Outcome(
          id: 2
          friendly_name: 'Friendly Outcome Name'
          mastery_points: 3
          points_possible: 5
        )
      })

    teardown: ->
      fakeENV.teardown()
      @server.restore()

  test '#initialize', ->
    ok @outcomeLineGraphView.collection instanceof OutcomeResultCollection,
      'should have an OutcomeResultCollection'
    ok !@outcomeLineGraphView.deferred.isResolved(),
      'should have unresolved promise'
    @outcomeLineGraphView.collection.trigger('fetched:last')
    ok @outcomeLineGraphView.deferred.isResolved(),
      'should resolve promise on fetched:last'

  test 'render', ->
    renderSpy = @spy(@outcomeLineGraphView, 'render')
    ok !@outcomeLineGraphView.deferred.isResolved(),
      'precondition'
    ok @outcomeLineGraphView.render()
    ok _.isUndefined(@outcomeLineGraphView.svg),
      'should not render svg if promise is unresolved'

    @outcomeLineGraphView.collection.trigger('fetched:last')
    ok renderSpy.calledTwice, 'promise should call render'
    ok _.isUndefined(@outcomeLineGraphView.svg),
      'should not render svg if collection is empty'

    @outcomeLineGraphView.collection.parse(@response)
    @outcomeLineGraphView.collection.add(
      @response['outcome_results'][0]
    )
    ok @outcomeLineGraphView.render()
    ok !_.isUndefined(@outcomeLineGraphView.svg),
      'should render svg if scores are present'
    ok @outcomeLineGraphView.$('.screenreader-only'),
      'should render table of data for screen reader'
