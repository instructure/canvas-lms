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

import Subject from '../question_answered_event_decorator'
import Backbone from '@canvas/backbone'

describe('Models.QuestionAnsweredEventDecorator', () => {
  describe('#decorateAnswerRecord', () => {
    describe('inferring whether a question is answered', () => {
      const record = {}
      let questionType
      const subject = function (answer) {
        record.answer = answer

        return Subject.decorateAnswerRecord(
          {
            questionType,
          },
          record
        )
      }

      it('multiple_choice_question and many friends (scalar answers)', function () {
        questionType = 'multiple_choice_question'

        subject(null)
        expect(record.answered).toEqual(false)

        subject('123')
        expect(record.answered).toEqual(true)
      })

      it('fill_in_multiple_blanks_question, multiple_dropdowns', function () {
        questionType = 'fill_in_multiple_blanks_question'

        subject({color1: null, color2: null})
        expect(record.answered).toEqual(false, 'should be false when all blanks are nulls')

        subject({color1: 'something', color2: null})
        expect(record.answered).toEqual(true, 'should be true if any blank is filled with anything')
      })

      it('matching_question', function () {
        questionType = 'matching_question'

        subject([])
        expect(record.answered).toEqual(false)

        subject(null)
        expect(record.answered).toEqual(false)

        subject([{answer_id: '123', match_id: null}])
        expect(record.answered).toEqual(false)

        subject([{answer_id: '123', match_id: '456'}])
        expect(record.answered).toEqual(true)
      })

      it('multiple_answers, file_upload', function () {
        questionType = 'matching_question'

        subject([])
        expect(record.answered).toEqual(false)

        subject(null)
        expect(record.answered).toEqual(false)

        subject(null)
        expect(record.answered).toEqual(false)
      })
    })
  })

  describe('#run', function () {
    it('should mark latest answers to all questions', function () {
      const events = [
        {
          data: [
            {quizQuestionId: '1', answer: 'something'},
            {quizQuestionId: '2', answer: null},
          ],
        },
        {
          data: [{quizQuestionId: '1', answer: 'something else'}],
        },
      ]

      const eventCollection = events.map(function (attrs) {
        return new Backbone.Model(attrs)
      })

      const questions = [{id: '1'}, {id: '2'}]

      const findQuestionRecord = (eventIndex, id) =>
        eventCollection[eventIndex].get('data').find(x => x.quizQuestionId === id)

      Subject.run(eventCollection, questions)

      expect(findQuestionRecord(0, '1').last).toBeFalsy()
      expect(findQuestionRecord(1, '1').last).toBeTruthy()

      expect(findQuestionRecord(0, '2').last).toBeTruthy()
    })
  })
})
