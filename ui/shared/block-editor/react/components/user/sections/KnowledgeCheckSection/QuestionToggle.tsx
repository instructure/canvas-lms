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

import React, {useState} from 'react'
import {Text} from '@instructure/ui-text'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {View} from '@instructure/ui-view'
import {renderQuestion} from './utils/questionUtils'
import {type QuestionProps} from './types'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

interface QuestionToggleProps {
  question: any
  onSelect: (question: QuestionProps | null) => void
}

const QuestionToggle: React.FC<QuestionToggleProps> = ({question, onSelect}) => {
  const [expanded, setExpanded] = useState<boolean>(false)

  const handleToggle = () => {
    if (supportedQuestionType()) {
      setExpanded(!expanded)
      onSelect(question)
    } else {
      onSelect(null)
    }
  }

  const questionType = () => {
    switch (question.entry.interaction_type_slug) {
      case 'true-false':
        return I18n.t('True/False')
      case 'choice':
        return I18n.t('Multiple Choice')
      case 'matching':
        return I18n.t('Matching')
      default:
        return I18n.t('Unsupported question type')
    }
  }

  const renderSummary = () => {
    return (
      <View as="div" padding="x-small" borderRadius="medium" borderWidth="small">
        <View
          as="div"
          maxWidth="3rem"
          background="primary-inverse"
          padding="small"
          textAlign="center"
        >
          {question.position}
        </View>
        <Text size="small" color="secondary">
          {questionType()}
        </Text>
        <br />
        <Text>
          {question.entry.title || I18n.t('Question %{position}', {position: question.position})}
        </Text>
      </View>
    )
  }

  const supportedQuestionType = () => {
    return ['true-false', 'choice', 'matching'].includes(question.entry.interaction_type_slug)
  }

  return (
    <div style={{opacity: supportedQuestionType() ? 1 : 0.5}}>
      <ToggleDetails
        summary={renderSummary()}
        iconPosition="end"
        fluidWidth={true}
        expanded={expanded}
        onToggle={handleToggle}
        data-testid={`question-toggle-${question.id}`}
      >
        {/* @ts-expect-error */}
        <View as="div" padding="small" opacity="50%">
          {renderQuestion(question.entry)}
        </View>
      </ToggleDetails>
    </div>
  )
}

export default QuestionToggle
