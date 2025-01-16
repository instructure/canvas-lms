/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import Backbone from '@canvas/backbone'
import CollectionView from '@canvas/backbone-collection-view'
import OutcomeResultCollection from '../../collections/OutcomeResultCollection'
import Outcome from '@canvas/grade-summary/backbone/models/Outcome'
import Group from '../../models/Group'
import OutcomeDetailView from '../OutcomeDetailView'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('OutcomeDetailView', () => {
  let outcomeDetailView
  const courseId = 1
  const userId = 6
  const outcomeId = 2
  const mockResponse = {
    outcome_results: [
      {
        id: '9',
        score: 1,
        submitted_or_assessed_at: '2015-03-13T16:23:26Z',
        links: {user: '6', learning_outcome: '2', alignment: 'assignment_1'},
      },
    ],
    linked: {
      alignments: [
        {
          id: 'assignment_1',
          name: 'This is the first assignment.',
          html_url: 'http://localhost:3000/courses/1/assignments/1',
        },
      ],
    },
  }

  beforeEach(() => {
    document.body.innerHTML = '<div id="application"></div>'

    // Mock jQuery dialog
    $.fn.dialog = jest.fn(() => $({}))

    // Mock Backbone sync
    Backbone.sync = (_method, _model, options) => {
      const deferred = $.Deferred()
      setTimeout(() => {
        options.success(mockResponse)
        deferred.resolve(mockResponse)
      }, 0)
      return deferred
    }

    fakeENV.setup()
    ENV.context_asset_string = `course_${courseId}`
    ENV.current_user = {display_name: 'Student One'}
    ENV.student_id = userId

    outcomeDetailView = new OutcomeDetailView({
      course_id: courseId,
      user_id: userId,
    })
  })

  afterEach(() => {
    fakeENV.teardown()
    outcomeDetailView.remove()
    document.body.innerHTML = ''
  })

  it('initializes with correct collections and views', () => {
    expect(outcomeDetailView.alignmentsForView).toBeInstanceOf(Backbone.Collection)
    expect(outcomeDetailView.alignmentsView).toBeInstanceOf(CollectionView)
  })

  it('renders all alignments', done => {
    const outcome = new Outcome({
      id: outcomeId,
      mastery_points: 3,
      points_possible: 5,
    })
    outcome.group = new Group({title: 'Outcome Group Title'})

    // Listen for the reset event on alignmentsForView
    outcomeDetailView.alignmentsForView.on('reset', () => {
      expect(outcomeDetailView.allAlignments).toBeInstanceOf(OutcomeResultCollection)
      expect(outcomeDetailView.alignmentsForView).toHaveLength(1)
      const alignment = outcomeDetailView.alignmentsForView.at(0)
      expect(alignment.get('links').alignment).toBe('assignment_1')
      done()
    })

    outcomeDetailView.show(outcome)
  })
})
