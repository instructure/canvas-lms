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

import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {uid} from '@instructure/uid'
import {type QuestionChoice} from '../../../../../assets/data/quizQuestions'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

type MultipleChoiceQuestionProps = {
  question: any
  onAnswerChange: (isCorrect: boolean) => void
}

const MultipleChoiceQuestion = ({question, onAnswerChange}: MultipleChoiceQuestionProps) => {
  const [correctAnswer] = useState<string>(question.scoring_data.value)
  const [answer, setAnswer] = useState<string | undefined>(undefined)
  const [qid] = useState<string>(uid('question', 2))

  const handleAnswerChange = useCallback(
    (_event: React.ChangeEvent<HTMLInputElement>, value: string) => {
      setAnswer(value)
      onAnswerChange(value === correctAnswer)
    },
    [correctAnswer, onAnswerChange],
  )

  return (
    <div className="quiz-section__body">
      <div style={{margin: '0 0 .75rem'}} dangerouslySetInnerHTML={{__html: question.item_body}} />
      <RadioInputGroup
        description={<ScreenReaderContent>{I18n.t('Choose one')}</ScreenReaderContent>}
        name={qid}
        value={answer}
        onChange={handleAnswerChange}
        key={`question-${question.id}`}
      >
        {question.interaction_data.choices.map((choice: QuestionChoice) => {
          return (
            <RadioInput
              key={choice.id}
              value={choice.id}
              label={<span dangerouslySetInnerHTML={{__html: choice.item_body}} />}
            />
          )
        })}
      </RadioInputGroup>
    </div>
  )
}

export {MultipleChoiceQuestion}
