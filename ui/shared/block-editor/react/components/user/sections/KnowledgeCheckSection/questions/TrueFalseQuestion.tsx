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
import {uid} from '@instructure/uid'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

type TrueFalseQuestionProps = {
  question: any
  onAnswerChange: (isCorrect: boolean) => void
}

const TrueFalseQuestion = ({question, onAnswerChange}: TrueFalseQuestionProps) => {
  const [correctAnswer] = useState<string>(question.scoring_data.value.toString().toLowerCase())
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
        <RadioInput
          value="true"
          label={question.interaction_data.true_choice}
          key={`true-${question.id}`}
        />
        <RadioInput
          value="false"
          label={question.interaction_data.false_choice}
          key={`false-${question.id}`}
        />
      </RadioInputGroup>
    </div>
  )
}

export {TrueFalseQuestion}
