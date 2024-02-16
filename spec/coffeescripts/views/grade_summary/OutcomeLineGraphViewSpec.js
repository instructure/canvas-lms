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

import $ from 'jquery'
import 'jquery-migrate'
import {isUndefined} from 'lodash'
import Outcome from '@canvas/grade-summary/backbone/models/Outcome'
import OutcomeResultCollection from 'ui/features/grade_summary/backbone/collections/OutcomeResultCollection'
import OutcomeLineGraphView from 'ui/features/grade_summary/backbone/views/OutcomeLineGraphView'
import * as tz from '@canvas/datetime'
import fakeENV from 'helpers/fakeENV'

QUnit.module('OutcomeLineGraphViewSpec', {
  setup() {
    fakeENV.setup()
    ENV.context_asset_string = 'course_1'
    ENV.current_user = {display_name: 'Student One'}
    ENV.student_id = 6
    this.server = sinon.fakeServer.create()
    this.response = {
      outcome_results: [
        {
          submitted_or_assessed_at: tz.parse('2015-04-24T19:27:54Z'),
          links: {alignment: 'alignment_1'},
        },
      ],
      linked: {
        alignments: [
          {
            id: 'alignment_1',
            name: 'Alignment Name',
          },
        ],
      },
    }
    this.outcomeLineGraphView = new OutcomeLineGraphView({
      el: $('<div class="line-graph"></div>')[0],
      model: new Outcome({
        id: 2,
        friendly_name: 'Friendly Outcome Name',
        mastery_points: 3,
        points_possible: 5,
      }),
    })
  },
  teardown() {
    fakeENV.teardown()
    return this.server.restore()
  },
})

test('#initialize', function () {
  ok(
    this.outcomeLineGraphView.collection instanceof OutcomeResultCollection,
    'should have an OutcomeResultCollection'
  )
  notStrictEqual(
    this.outcomeLineGraphView.deferred.state(),
    'resolved',
    'should have unresolved promise'
  )
  this.outcomeLineGraphView.collection.trigger('fetched:last')
  strictEqual(
    this.outcomeLineGraphView.deferred.state(),
    'resolved',
    'should resolve promise on fetched:last'
  )
})

test('render', function () {
  const renderSpy = sandbox.spy(this.outcomeLineGraphView, 'render')
  notStrictEqual(this.outcomeLineGraphView.deferred.state(), 'resolved', 'precondition')
  ok(this.outcomeLineGraphView.render())
  ok(isUndefined(this.outcomeLineGraphView.svg), 'should not render svg if promise is unresolved')
  this.outcomeLineGraphView.collection.trigger('fetched:last')
  ok(renderSpy.calledTwice, 'promise should call render')
  ok(isUndefined(this.outcomeLineGraphView.svg), 'should not render svg if collection is empty')
  this.outcomeLineGraphView.collection.parse(this.response)
  this.outcomeLineGraphView.collection.add(this.response.outcome_results[0])
  ok(this.outcomeLineGraphView.render())
  ok(!isUndefined(this.outcomeLineGraphView.svg), 'should render svg if scores are present')
  ok(
    this.outcomeLineGraphView.$('.screenreader-only'),
    'should render table of data for screen reader'
  )
})
