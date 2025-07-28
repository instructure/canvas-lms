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

import React from 'react'
import {TrueFalseQuestion} from '../questions/TrueFalseQuestion'
import {MultipleChoiceQuestion} from '../questions/MultipleChoiceQuestion'
import {MatchingQuestion} from '../questions/MatchingQuestion'
import {Alert} from '@instructure/ui-alerts'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {QuestionProps} from '../types'

const I18n = createI18nScope('block-editor')

const defaultHandleCheckAnswer = (_result: boolean) => true

export const renderQuestion = (
  question: QuestionProps,
  handleCheckAnswer: (result: boolean) => void = defaultHandleCheckAnswer,
) => {
  // @ts-expect-error
  switch (question.interaction_type_slug) {
    case 'true-false':
      return <TrueFalseQuestion question={question} onAnswerChange={handleCheckAnswer} />
    case 'choice':
      return <MultipleChoiceQuestion question={question} onAnswerChange={handleCheckAnswer} />
    case 'matching':
      return <MatchingQuestion question={question} onAnswerChange={handleCheckAnswer} />
    default:
      return <Alert variant="error">{I18n.t('Unsupported question type')}</Alert>
  }
}
