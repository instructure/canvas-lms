/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {IconInfoLine} from '@instructure/ui-icons'
import {Tooltip} from '@instructure/ui-tooltip'

const I18n = createI18nScope('assignment_quiz_type')

type QuizType = 'graded_quiz' | 'graded_survey' | 'ungraded_survey'

interface QuizTypeSelectorComponentProps {
  quizType: QuizType
  isExistingAssignment: boolean
  onChange: (quizType: QuizType) => void
  shouldRenderLabel?: boolean
}

interface QuizTypeSelectorContentProps {
  quizType: QuizType
  isExistingAssignment: boolean
  onChange: (quizType: QuizType) => void
}

const QuizTypeSelectorContent: React.FC<QuizTypeSelectorContentProps> = ({
  quizType,
  isExistingAssignment,
  onChange,
}) => {
  const quizTypeOptions = [
    {
      id: 'graded_quiz',
      label: I18n.t('quiz_type_options.graded_quiz', 'Graded Quiz'),
    },
    {
      id: 'graded_survey',
      label: I18n.t('quiz_type_options.graded_survey', 'Graded Survey'),
    },
    {
      id: 'ungraded_survey',
      label: I18n.t('quiz_type_options.ungraded_survey', 'Ungraded Survey'),
    },
  ]

  const handleChange = (event: React.ChangeEvent<HTMLSelectElement>) => {
    onChange(event.target.value as QuizType)
  }

  return (
    <div className="form-column-right" style={{width: 'unset', marginBottom: '12px'}}>
      <Flex alignItems="center" gap="small">
        <select
          id="assignment_quiz_type"
          name="new_quizzes_quiz_type"
          value={quizType}
          onChange={handleChange}
          disabled={isExistingAssignment}
          style={{width: '392px', marginBottom: 'unset'}}
        >
          {quizTypeOptions.map(option => (
            <option key={option.id} value={option.id}>
              {option.label}
            </option>
          ))}
        </select>
        <Tooltip
          renderTip={
            isExistingAssignment
              ? I18n.t(
                  'quiz_type_locked_tooltip',
                  'Quiz Type can only be set when creating a new assignment',
                )
              : I18n.t(
                  'quiz_type_locked_after_save_tooltip',
                  'After saving these settings, the quiz type is locked and cannot be changed.',
                )
          }
          placement="end"
        >
          <IconInfoLine />
        </Tooltip>
      </Flex>
    </div>
  )
}

export const QuizTypeSelectorComponent: React.FC<QuizTypeSelectorComponentProps> = ({
  quizType,
  isExistingAssignment,
  onChange,
  shouldRenderLabel = true,
}) => {
  if (!shouldRenderLabel) {
    return (
      <QuizTypeSelectorContent
        quizType={quizType}
        isExistingAssignment={isExistingAssignment}
        onChange={onChange}
      />
    )
  }

  return (
    <React.Fragment>
      <div className="form-column-left no-group">
        <label htmlFor="assignment_quiz_type">{I18n.t('quiz_type', 'Quiz Type')}</label>
      </div>
      {' ' /* to align with the existing form elements on the assignment edit page */}
      <QuizTypeSelectorContent
        quizType={quizType}
        isExistingAssignment={isExistingAssignment}
        onChange={onChange}
      />
    </React.Fragment>
  )
}
