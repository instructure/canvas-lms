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

import React, {useCallback, useState} from 'react'

import {SimpleSelect} from '@instructure/ui-simple-select'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

type MatchingQuestionProps = {
  question: any
  onAnswerChange: (isCorrect: boolean) => void
}

interface MatchingQuestionType {
  id: string
  item_body: string
}

type MatchingQuestionAnswerKey = Record<string, string> // <id, answer>
type MatchingQuestionAnswers = Record<string, string | undefined> // <id, users_answer>

const MatchingQuestion = ({question, onAnswerChange}: MatchingQuestionProps) => {
  const [correctAnswers] = useState<MatchingQuestionAnswerKey>(question.scoring_data.value)
  const [answers, setAnswers] = useState<MatchingQuestionAnswers>(() => {
    return question.interaction_data.questions.reduce(
      (acc: MatchingQuestionAnswers, curr: MatchingQuestionAnswerKey) => {
        return {
          ...acc,
          [curr.id]: undefined,
        }
      },
      {} as MatchingQuestionAnswers
    )
  })

  const handleAnswerChange = useCallback(
    (
      event: React.SyntheticEvent,
      data: {
        value?: string | number
        id?: string
      }
    ) => {
      if (!data.id || !data.value) return

      const currAnswers = {...answers}
      const qid = data.id.split('-')[0]
      currAnswers[qid] = data.value as string
      setAnswers(currAnswers)
      const isCorrect = Object.keys(currAnswers).every((id: string) => id === currAnswers[id])
      onAnswerChange(isCorrect)
    },
    [answers, onAnswerChange, setAnswers]
  )

  const renderChoices = () => {
    const choices = question.interaction_data.questions.map((q: MatchingQuestionType) => {
      return (
        <div key={q.id} className="matching-question__question">
          <div className="matching-question__left">{q.item_body}</div>
          <div className="matching-question__center" />
          <div className="matching-question__right">
            <SimpleSelect
              renderLabel={<ScreenReaderContent>Pick a matching answer</ScreenReaderContent>}
              assistiveText="Use arrow keys to navigate options"
              value={answers[q.id]}
              onChange={handleAnswerChange}
            >
              <SimpleSelect.Option id="none" value="">
                ---
              </SimpleSelect.Option>
              {Object.keys(correctAnswers).map((aid: string) => {
                return (
                  <SimpleSelect.Option key={`${q.id}-${aid}`} id={`${q.id}-${aid}`} value={aid}>
                    {question.scoring_data.value[aid]}
                  </SimpleSelect.Option>
                )
              })}
            </SimpleSelect>
          </div>
        </div>
      )
    })
    return choices
  }

  return (
    <div className="quiz-section__body">
      <div style={{margin: '0 0 .75rem'}} dangerouslySetInnerHTML={{__html: question.item_body}} />
      {renderChoices()}
    </div>
  )
}

export {MatchingQuestion}
