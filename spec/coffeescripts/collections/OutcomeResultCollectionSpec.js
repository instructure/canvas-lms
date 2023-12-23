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

import Backbone from '@canvas/backbone'
import Outcome from '@canvas/grade-summary/backbone/models/Outcome'
import OutcomeResultCollection from 'ui/features/grade_summary/backbone/collections/OutcomeResultCollection'
import fakeENV from 'helpers/fakeENV'
import * as tz from '@canvas/datetime'

QUnit.module('OutcomeResultCollectionSpec', {
  setup() {
    fakeENV.setup()
    ENV.context_asset_string = 'course_1'
    ENV.student_id = '1'
    this.outcome = new Outcome({
      mastery_points: 8,
      points_possible: 10,
    })
    this.outcome2 = new Outcome({
      mastery_points: 8,
      points_possible: 0,
    })
    this.outcomeResultCollection = new OutcomeResultCollection([], {outcome: this.outcome})
    this.outcomeResultCollection2 = new OutcomeResultCollection([], {outcome: this.outcome2})
    this.alignmentName = 'First Alignment Name'
    this.alignmentName2 = 'Second Alignment Name'
    this.alignmentName3 = 'Third Alignment Name'
    this.response = {
      outcome_results: [
        {
          submitted_or_assessed_at: tz.parse('2015-04-24T19:27:54Z'),
          links: {alignment: 'alignment_1'},
          percent: 0.4,
        },
      ],
      linked: {
        alignments: [
          {
            id: 'alignment_1',
            name: this.alignmentName,
          },
        ],
      },
    }
    this.response2 = {
      outcome_results: [
        {
          submitted_or_assessed_at: tz.parse('2015-04-24T19:27:54Z'),
          links: {alignment: 'alignment_1'},
        },
        {
          submitted_or_assessed_at: tz.parse('2015-04-23T19:27:54Z'),
          links: {alignment: 'alignment_2'},
        },
        {
          submitted_or_assessed_at: tz.parse('2015-04-25T19:27:54Z'),
          links: {alignment: 'alignment_3'},
        },
      ],
      linked: {
        alignments: [
          {
            id: 'alignment_1',
            name: this.alignmentName,
          },
          {
            id: 'alignment_2',
            name: this.alignmentName2,
          },
          {
            id: 'alignment_3',
            name: this.alignmentName3,
          },
        ],
      },
    }
  },
  teardown() {
    fakeENV.teardown()
  },
})

test('default params reflect aligned outcome', function () {
  // eslint-disable-next-line new-cap
  const collectionModel = new this.outcomeResultCollection.model()
  deepEqual(collectionModel.get('mastery_points'), 8)
  deepEqual(collectionModel.get('points_possible'), 10)
})

test('#parse', function () {
  ok(!this.outcomeResultCollection.alignments, 'precondition')
  ok(this.outcomeResultCollection.parse(this.response))
  ok(this.outcomeResultCollection.alignments instanceof Backbone.Collection)
  ok(this.outcomeResultCollection.alignments.length, 1)
})

test('#handleAdd', function () {
  equal(this.outcomeResultCollection.length, 0, 'precondition')
  this.outcomeResultCollection.alignments = new Backbone.Collection(this.response.linked.alignments)
  ok(this.outcomeResultCollection.add(this.response.outcome_results[0]))
  ok(this.outcomeResultCollection.length, 1)
  equal(this.alignmentName, this.outcomeResultCollection.first().get('alignment_name'))
  equal(this.outcomeResultCollection.first().get('score'), 4.0)
})

test('#handleAdd 0 points_possible', function () {
  equal(this.outcomeResultCollection2.length, 0, 'precondition')
  this.outcomeResultCollection2.alignments = new Backbone.Collection(
    this.response.linked.alignments
  )
  ok(this.outcomeResultCollection2.add(this.response.outcome_results[0]))
  ok(this.outcomeResultCollection2.length, 1)
  equal(this.outcomeResultCollection2.first().get('score'), 3.2)
})

test('#handleSort', function () {
  equal(this.outcomeResultCollection.length, 0, 'precondition')
  this.outcomeResultCollection.alignments = new Backbone.Collection(
    this.response2.linked.alignments
  )
  ok(this.outcomeResultCollection.add(this.response2.outcome_results[0]))
  ok(this.outcomeResultCollection.add(this.response2.outcome_results[1]))
  ok(this.outcomeResultCollection.add(this.response2.outcome_results[2]))
  ok(this.outcomeResultCollection.length, 3)
  equal(this.alignmentName3, this.outcomeResultCollection.at(0).get('alignment_name'))
  equal(this.alignmentName, this.outcomeResultCollection.at(1).get('alignment_name'))
  equal(this.alignmentName2, this.outcomeResultCollection.at(2).get('alignment_name'))
})
