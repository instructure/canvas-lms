/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import Subject from '../quiz_statistics'
import fixture from '../../../__tests__/fixtures/quiz_statistics_all_types.json'

it('parses', function () {
  const subject = new Subject(fixture.quiz_statistics[0], {parse: true})

  expect(subject.get('id')).toBe('267')
  expect(subject.get('pointsPossible')).toBe(16)

  expect(typeof subject.get('submissionStatistics')).toBe('object')
  expect(subject.get('submissionStatistics').uniqueCount).toBe(156)
  expect(subject.get('questionStatistics').length).toBe(13)
})

it('parses the discrimination index', function () {
  const subject = new Subject(fixture.quiz_statistics[0], {parse: true})

  expect(subject.get('id')).toBe('267')
  expect(subject.get('questionStatistics')[0].discriminationIndex).toBe(0.7157094891780442)
})

describe('calculating participant count', function () {
  it('uses the number of students who actually took the question', function () {
    const subject = new Subject(
      {
        question_statistics: [
          {
            question_type: 'multiple_choice_question',
            answers: [
              {id: '1', responses: 2},
              {id: '2', responses: 3},
            ],
          },
        ],
      },
      {parse: true}
    )

    expect(subject.get('questionStatistics')[0].participantCount).toEqual(5)
  })

  it('works with questions that have answer sets', function () {
    const subject = new Subject(
      {
        question_statistics: [
          {
            question_type: 'fill_in_multiple_blanks_question',
            answer_sets: [
              {
                id: 'some answer set',
                answers: [
                  {id: '1', responses: 2},
                  {id: '2', responses: 3},
                ],
              },
              {
                id: 'some other answer set',
                answers: [
                  {id: '3', responses: 0},
                  {id: '4', responses: 5},
                ],
              },
            ],
          },
        ],
      },
      {parse: true}
    )

    expect(subject.get('questionStatistics')[0].participantCount).toEqual(5)
  })

  it('works with multiple_answers_questions', function () {
    const subject = new Subject(
      {
        question_statistics: [
          {
            question_type: 'multiple_answers_question',
            responses: 2,
            correct: 1,
            answers: [
              {id: '6122', text: 'a', correct: true, responses: 2},
              {id: '6863', text: 'b', correct: true, responses: 2},
              {id: '3938', text: 'c', correct: true, responses: 2},
              {id: '938', text: 'd', correct: false, responses: 1},
            ],
          },
        ],
      },
      {parse: true}
    )

    expect(subject.get('questionStatistics')[0].participantCount).toEqual(2)
  })
})
