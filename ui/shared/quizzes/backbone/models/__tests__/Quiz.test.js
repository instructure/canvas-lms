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
import 'jquery-migrate'
import Quiz from '../Quiz'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import AssignmentOverrideCollection from '@canvas/assignments/backbone/collections/AssignmentOverrideCollection'
import fakeENV from '@canvas/test-utils/fakeENV'
import '@canvas/jquery/jquery.ajaxJSON'
import PandaPubPoller from '@canvas/panda-pub-poller'
import {http, HttpResponse} from 'msw'
import {mswServer} from '../../../../msw/mswServer'

jest.mock('@canvas/panda-pub-poller')

const server = mswServer([])

describe('Quiz', () => {
  let quiz

  beforeAll(() => {
    server.listen()
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(() => {
    quiz = new Quiz({
      id: 1,
      html_url: 'http://localhost:3000/courses/1/quizzes/24',
    })
  })

  afterEach(() => {
    server.resetHandlers()
    jest.restoreAllMocks()
  })

  it('ignores assignment if not given', () => {
    expect(quiz.get('assignment')).toBeFalsy()
  })

  it('sets assignment', () => {
    const assign = {
      id: 1,
      title: 'Foo Bar',
    }
    quiz = new Quiz({assignment: assign})
    expect(quiz.get('assignment')).toBeInstanceOf(Assignment)
  })

  it('ignores assignment_overrides if not given', () => {
    expect(quiz.get('assignment_overrides')).toBeFalsy()
  })

  it('assigns assignment_override collection', () => {
    quiz = new Quiz({assignment_overrides: []})
    expect(quiz.get('assignment_overrides')).toBeInstanceOf(AssignmentOverrideCollection)
  })

  it('should set url from html url', () => {
    expect(quiz.get('url')).toBe('http://localhost:3000/courses/1/quizzes/1')
  })

  it('should set edit_url from html url', () => {
    expect(quiz.get('edit_url')).toBe('http://localhost:3000/courses/1/quizzes/1/edit')
  })

  it('should set publish_url from html url', () => {
    expect(quiz.get('publish_url')).toBe('http://localhost:3000/courses/1/quizzes/publish')
  })

  it('should set unpublish_url from html url', () => {
    expect(quiz.get('unpublish_url')).toBe('http://localhost:3000/courses/1/quizzes/unpublish')
  })

  it('should set deletion_url from html url', () => {
    expect(quiz.get('deletion_url')).toBe('http://localhost:3000/courses/1/quizzes/1')
  })

  it('should set title_label from title', () => {
    quiz = new Quiz({
      title: 'My Quiz!',
      readable_type: 'Quiz',
    })
    expect(quiz.get('title_label')).toBe('My Quiz!')
  })

  it('should set title_label from readable_type', () => {
    quiz = new Quiz({readable_type: 'Quiz'})
    expect(quiz.get('title_label')).toBe('Quiz')
  })

  it('defaults unpublishable to true', () => {
    expect(quiz.get('unpublishable')).toBeTruthy()
  })

  it('sets unpublishable to false', () => {
    quiz = new Quiz({unpublishable: false})
    expect(quiz.get('unpublishable')).toBeFalsy()
  })

  it('sets publishable from can_unpublish and published', () => {
    quiz = new Quiz({
      can_unpublish: false,
      published: true,
    })
    expect(quiz.get('unpublishable')).toBeFalsy()
  })

  it('sets question count', () => {
    quiz = new Quiz({
      question_count: 1,
      published: true,
    })
    expect(quiz.get('question_count_label')).toBe('1 Question')
    quiz = new Quiz({
      question_count: 2,
      published: true,
    })
    expect(quiz.get('question_count_label')).toBe('2 Questions')
  })

  it('sets possible points count with no points', () => {
    quiz = new Quiz()
    expect(quiz.get('possible_points_label')).toBe('')
  })

  it('sets possible points count with 0 points', () => {
    quiz = new Quiz({points_possible: 0})
    expect(quiz.get('possible_points_label')).toBe('')
  })

  it('sets possible points count with 1 point', () => {
    quiz = new Quiz({points_possible: 1})
    expect(quiz.get('possible_points_label')).toBe('1 pt')
  })

  it('sets possible points count with 2 points', () => {
    quiz = new Quiz({points_possible: 2})
    expect(quiz.get('possible_points_label')).toBe('2 pts')
  })

  it('sets possible points count with 1.23 points', () => {
    quiz = new Quiz({points_possible: 1.23})
    expect(quiz.get('possible_points_label')).toBe('1.23 pts')
  })

  it('points possible to null if ungraded survey', () => {
    quiz = new Quiz({
      points_possible: 5,
      quiz_type: 'survey',
    })
    expect(quiz.get('possible_points_label')).toBe('')
  })

  it('saves to the server on publish', async () => {
    let requestReceived = false
    server.use(
      http.post('*/courses/1/quizzes/publish', () => {
        requestReceived = true
        return HttpResponse.json({})
      }),
    )

    await quiz.publish()
    expect(requestReceived).toBe(true)
  })

  it('sets published attribute to true on publish', () => {
    quiz.publish()
    expect(quiz.get('published')).toBeTruthy()
  })

  it('saves to the server on unpublish', async () => {
    let requestReceived = false
    server.use(
      http.post('*/courses/1/quizzes/unpublish', () => {
        requestReceived = true
        return HttpResponse.json({})
      }),
    )

    await quiz.unpublish()
    expect(requestReceived).toBe(true)
  })

  it('sets published attribute to false on unpublish', () => {
    quiz.unpublish()
    expect(quiz.get('published')).toBeFalsy()
  })
})

describe('Quiz#multipleDueDates', () => {
  it('checks for multiple due dates from assignment overrides', () => {
    const quiz = new Quiz({
      all_dates: [{title: 'Winter'}, {title: 'Summer'}],
    })
    expect(quiz.multipleDueDates()).toBeTruthy()
  })

  it('checks for no multiple due dates from quiz overrides', () => {
    const quiz = new Quiz()
    expect(quiz.multipleDueDates()).toBeFalsy()
  })
})

describe('Quiz.Next', () => {
  const testUrl = (isFeatureFlagEnabled, expectedDisplay) => {
    let quiz
    describe(`when new_quizzes_navigation_updates FF is ${isFeatureFlagEnabled ? 'enabled' : 'disabled'}`, () => {
      beforeEach(() => {
        fakeENV.setup({
          FEATURES: {
            new_quizzes_navigation_updates: isFeatureFlagEnabled,
          },
        })
        quiz = new Quiz({
          id: 7,
          html_url: 'http://localhost:3000/courses/1/assignments/7',
          assignment_id: 7,
          quiz_type: 'quizzes.next',
        })
      })

      afterEach(() => {
        fakeENV.teardown()
      })

      it(`should set build url from html url using ${expectedDisplay} display type`, () => {
        expect(quiz.get('build_url')).toBe(
          `http://localhost:3000/courses/1/assignments/7?display=${expectedDisplay}`,
        )
      })
    })
  }

  testUrl(true, 'full_width_with_nav')
  testUrl(false, 'full_width')
})

describe('Quiz.Next with manage enabled', () => {
  let quiz

  beforeEach(() => {
    fakeENV.setup({
      PERMISSIONS: {manage: true},
    })
    quiz = new Quiz({
      id: 7,
      html_url: 'http://localhost:3000/courses/1/assignments/7',
      assignment_id: 7,
      quiz_type: 'quizzes.next',
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('should set url as edit_url', () => {
    expect(quiz.get('url')).toBe('http://localhost:3000/courses/1/assignments/7/edit?quiz_lti')
  })
})

describe('Quiz polling', () => {
  let quiz
  let fetchMock
  let pollerMock

  beforeEach(() => {
    fakeENV.setup({
      FEATURES: {
        new_quizzes_navigation_updates: false,
      },
    })
    jest.useFakeTimers()
    quiz = new Quiz({
      id: 7,
      course_id: 1,
      html_url: 'http://localhost:3000/courses/1/assignments/7',
      assignment_id: 7,
      quiz_type: 'quizzes.next',
      workflow_state: 'duplicating',
    })

    // Mock fetch to return a jQuery-like promise with always
    fetchMock = jest.spyOn(quiz, 'fetch').mockImplementation(() => ({
      always: callback => {
        callback()
        return Promise.resolve()
      },
    }))

    pollerMock = {
      start: jest.fn(),
      stop: jest.fn(),
    }
    PandaPubPoller.mockImplementation((_interval, _maxAttempts, callback) => {
      callback(() => {})
      return pollerMock
    })
  })

  afterEach(() => {
    jest.restoreAllMocks()
    jest.useRealTimers()
  })

  it('polls for updates (duplicate)', () => {
    quiz.pollUntilFinishedLoading(4000)
    expect(fetchMock).toHaveBeenCalledWith({
      url: '/api/v1/courses/1/assignments/7?result_type=Quiz',
    })
    expect(pollerMock.start).toHaveBeenCalled()
  })

  it('polls for updates (migration)', () => {
    quiz.set('workflow_state', 'migrating')
    quiz.pollUntilFinishedLoading(4000)
    expect(fetchMock).toHaveBeenCalledWith({
      url: '/api/v1/courses/1/assignments/7?result_type=Quiz',
    })
    expect(pollerMock.start).toHaveBeenCalled()
  })

  it('polls for updates (importing)', () => {
    quiz.set('workflow_state', 'importing')
    quiz.pollUntilFinishedLoading(4000)
    expect(fetchMock).toHaveBeenCalledWith({
      url: '/api/v1/courses/1/assignments/7?result_type=Quiz',
    })
    expect(pollerMock.start).toHaveBeenCalled()
  })
})
