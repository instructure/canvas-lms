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
import Outcome from '@canvas/grade-summary/backbone/models/Outcome'
import OutcomeResultCollection from '../../collections/OutcomeResultCollection'
import OutcomeLineGraphView from '../OutcomeLineGraphView'
import * as tz from '@instructure/moment-utils'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('OutcomeLineGraphView', () => {
  let outcomeLineGraphView
  const response = {
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

  beforeEach(() => {
    fakeENV.setup()
    ENV.context_asset_string = 'course_1'
    ENV.current_user = {display_name: 'Student One'}
    ENV.student_id = 6
    outcomeLineGraphView = new OutcomeLineGraphView({
      el: $('<div class="line-graph"></div>')[0],
      model: new Outcome({
        id: 2,
        friendly_name: 'Friendly Outcome Name',
        mastery_points: 3,
        points_possible: 5,
      }),
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('should have an OutcomeResultCollection', () => {
    expect(outcomeLineGraphView.collection).toBeInstanceOf(OutcomeResultCollection)
  })

  it('should have unresolved promise initially', () => {
    expect(outcomeLineGraphView.deferred.state()).not.toBe('resolved')
  })

  it('should resolve promise on fetched:last', () => {
    outcomeLineGraphView.collection.trigger('fetched:last')
    expect(outcomeLineGraphView.deferred.state()).toBe('resolved')
  })

  it('should render correctly', () => {
    const renderSpy = jest.spyOn(outcomeLineGraphView, 'render')
    expect(outcomeLineGraphView.render()).toBeTruthy()
    expect(outcomeLineGraphView.svg).toBeUndefined()
    outcomeLineGraphView.collection.trigger('fetched:last')
    expect(renderSpy).toHaveBeenCalledTimes(2)
    expect(outcomeLineGraphView.svg).toBeUndefined()
    outcomeLineGraphView.collection.parse(response)
    outcomeLineGraphView.collection.add(response.outcome_results[0])
    expect(outcomeLineGraphView.render()).toBeTruthy()
    expect(outcomeLineGraphView.svg).not.toBeUndefined()
    expect(outcomeLineGraphView.$('.screenreader-only')).toBeTruthy()
  })
})
