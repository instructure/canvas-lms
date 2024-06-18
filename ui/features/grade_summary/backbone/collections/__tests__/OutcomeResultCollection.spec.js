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
import OutcomeResultCollection from '../OutcomeResultCollection'
import fakeENV from '@canvas/test-utils/fakeENV'
import * as tz from '@instructure/moment-utils'

describe('OutcomeResultCollection', () => {
  let studentDatastore
  let userStudentMap
  let testStudentMap
  let outcome
  let outcome2
  let outcomeResultCollection
  let outcomeResultCollection2
  let alignmentName
  let alignmentName2
  let alignmentName3
  let response
  let response2

  beforeEach(() => {
    fakeENV.setup()
    ENV.context_asset_string = 'course_1'
    ENV.student_id = '1'
    outcome = new Outcome({
      mastery_points: 8,
      points_possible: 10,
    })
    outcome2 = new Outcome({
      mastery_points: 8,
      points_possible: 0,
    })
    outcomeResultCollection = new OutcomeResultCollection([], {outcome})
    outcomeResultCollection2 = new OutcomeResultCollection([], {outcome: outcome2})
    alignmentName = 'First Alignment Name'
    alignmentName2 = 'Second Alignment Name'
    alignmentName3 = 'Third Alignment Name'
    response = {
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
            name: alignmentName,
          },
        ],
      },
    }
    response2 = {
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
            name: alignmentName,
          },
          {
            id: 'alignment_2',
            name: alignmentName2,
          },
          {
            id: 'alignment_3',
            name: alignmentName3,
          },
        ],
      },
    }
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  test('default params reflect aligned outcome', () => {
    // eslint-disable-next-line new-cap
    const collectionModel = new outcomeResultCollection.model()
    expect(collectionModel.get('mastery_points')).toBe(8)
    expect(collectionModel.get('points_possible')).toBe(10)
  })

  test('#parse', () => {
    expect(outcomeResultCollection.alignments).toBeUndefined()
    expect(outcomeResultCollection.parse(response)).toBeTruthy()
    expect(outcomeResultCollection.alignments).toBeInstanceOf(Backbone.Collection)
    expect(outcomeResultCollection.alignments.length).toBe(1)
  })

  test('#handleAdd', () => {
    expect(outcomeResultCollection.length).toBe(0)
    outcomeResultCollection.alignments = new Backbone.Collection(response.linked.alignments)
    expect(outcomeResultCollection.add(response.outcome_results[0])).toBeTruthy()
    expect(outcomeResultCollection.length).toBe(1)
    expect(outcomeResultCollection.first().get('alignment_name')).toBe(alignmentName)
    expect(outcomeResultCollection.first().get('score')).toBe(4.0)
  })

  test('#handleAdd 0 points_possible', () => {
    expect(outcomeResultCollection2.length).toBe(0)
    outcomeResultCollection2.alignments = new Backbone.Collection(response.linked.alignments)
    expect(outcomeResultCollection2.add(response.outcome_results[0])).toBeTruthy()
    expect(outcomeResultCollection2.length).toBe(1)
    expect(outcomeResultCollection2.first().get('score')).toBe(3.2)
  })

  test('#handleSort', () => {
    expect(outcomeResultCollection.length).toBe(0)
    outcomeResultCollection.alignments = new Backbone.Collection(response2.linked.alignments)
    expect(outcomeResultCollection.add(response2.outcome_results[0])).toBeTruthy()
    expect(outcomeResultCollection.add(response2.outcome_results[1])).toBeTruthy()
    expect(outcomeResultCollection.add(response2.outcome_results[2])).toBeTruthy()
    expect(outcomeResultCollection.length).toBe(3)
    expect(outcomeResultCollection.at(0).get('alignment_name')).toBe(alignmentName3)
    expect(outcomeResultCollection.at(1).get('alignment_name')).toBe(alignmentName)
    expect(outcomeResultCollection.at(2).get('alignment_name')).toBe(alignmentName2)
  })
})
