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

import React, {useCallback, useEffect, useState} from 'react'
import {useEditor, useNode} from '@craftjs/core'

import {Alert} from '@instructure/ui-alerts'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconCanvasLogoLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {useClassNames} from '../../../../utils'
import {KnowledgeCheckSectionToolbar} from './KnowledgeCheckSectionToolbar'
import {QuizModal} from './QuizModal'
import {renderQuestion} from './utils/questionUtils'
import {type QuestionProps, type KnowledgeCheckSectionProps} from './types'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

const WIDTH = 'auto'
const HEIGHT = 'auto'

const KnowledgeCheckSection = ({id, entry}: KnowledgeCheckSectionProps) => {
  const {enabled} = useEditor(state => {
    return {
      enabled: state.options.enabled,
    }
  })
  const {
    actions: {setProp},
    connectors: {connect, drag},
  } = useNode()
  const [question, setQuestion] = useState(entry)
  const [isCorrect, setIsCorrect] = useState<boolean | null>(null)
  const [showResult, setShowResult] = useState(false)
  const [modalOpen, setModalOpen] = useState(false)
  const clazz = useClassNames(enabled, {empty: false}, ['section', 'quiz-section'])

  useEffect(() => {
    setQuestion(entry)
    setIsCorrect(null)
    setShowResult(false)
  }, [entry])

  const handleCheckAnswer = useCallback((result: boolean) => {
    setIsCorrect(result)
    setShowResult(false)
  }, [])

  const handleSubmit = useCallback(() => {
    setShowResult(true)
  }, [])

  const showModal = useCallback(() => {
    setModalOpen(true)
  }, [])

  const handleSelectQuestion = useCallback(
    (newQuestion: QuestionProps) => {
      setProp((prps: KnowledgeCheckSectionProps) => {
        prps.id = newQuestion.id
        prps.entry = newQuestion.entry
      })
      setQuestion(newQuestion.entry)
      setModalOpen(false)
    },
    [setProp],
  )

  const renderFeedback = () => {
    if (isCorrect) {
      if (question.feedback && question.feedback.correct) {
        return question.feedback.correct
      } else {
        return I18n.t('Correct!')
      }
    } else if (question.feedback && question.feedback.incorrect) {
      return question.feedback.incorrect
    } else {
      return I18n.t('Bzzzzt, try again.')
    }
  }

  const renderNeutralFeedback = () => {
    if (question.feedback && question.feedback.neutral) {
      return question.feedback.neutral
    }
  }

  const renderSelectQuestionButton = () => {
    return (
      <div className="quiz-section__empty">
        {enabled ? (
          <Button onClick={showModal} color="secondary">
            {I18n.t('Select Quiz')}
          </Button>
        ) : (
          <Text>{I18n.t('No question has been selected')}</Text>
        )}
      </div>
    )
  }

  const renderQuestionOrSelectButton = () => {
    if (question) {
      // @ts-expect-error
      return renderQuestion(question, handleCheckAnswer)
    }
    return renderSelectQuestionButton()
  }

  return (
    <div
      id={id}
      className={clazz}
      ref={ref => {
        ref && connect(drag(ref))
      }}
      style={{width: WIDTH, height: HEIGHT}}
    >
      <div className="block-header">
        <IconCanvasLogoLine size="x-small" inline={true} style={{margin: 'auto 0'}} />
        <span className="block-header-title">{I18n.t('Check Your Knowledge')}</span>
      </div>
      {renderQuestionOrSelectButton()}
      <Flex justifyItems="space-between" padding="small">
        <Flex.Item shouldGrow={true}>
          {showResult && (
            <Alert variant={isCorrect ? 'success' : 'error'} margin="0 small 0 0">
              <div dangerouslySetInnerHTML={{__html: renderFeedback()}} />
              {/* @ts-expect-error */}
              <div dangerouslySetInnerHTML={{__html: renderNeutralFeedback()}} />
            </Alert>
          )}
        </Flex.Item>
        <Button
          color="secondary"
          onClick={handleSubmit}
          interaction={!enabled && question ? 'enabled' : 'disabled'}
        >
          {I18n.t('Check')}
        </Button>
      </Flex>
      {enabled && (
        <QuizModal
          open={modalOpen}
          onClose={() => setModalOpen(false)}
          onSelect={handleSelectQuestion}
        />
      )}
    </div>
  )
}

KnowledgeCheckSection.craft = {
  displayName: I18n.t('Knowledge Check'),
  defaultProps: {
    entry: undefined,
  },
  custom: {
    isSection: true,
  },
  related: {
    toolbar: KnowledgeCheckSectionToolbar,
  },
}

export {KnowledgeCheckSection}
