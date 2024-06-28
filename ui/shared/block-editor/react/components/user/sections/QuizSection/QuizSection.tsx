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
import {Text} from '@instructure/ui-text'

import {MultipleChoiceQuestion} from './questions/MultipleChoiceQuestion'
import {TrueFalseQuestion} from './questions/TrueFalseQuestion'
import {MatchingQuestion} from './questions/MatchingQuestion'
import {quizQuestions} from '../../../../assets/data/quizQuestions'
import {IconQuizSolid} from '@instructure/ui-icons'
import {useClassNames} from '../../../../utils'
import {QuizSectionMenu} from './QuizSectionMenu'
import {QuizModal} from './QuizModal'

const WIDTH = 'auto'
const HEIGHT = 'auto'

type QuizSectionProps = {
  questionId?: string
}

const QuizSection = ({questionId}: QuizSectionProps) => {
  const {enabled} = useEditor(state => {
    return {
      enabled: state.options.enabled,
    }
  })
  const {
    actions: {setProp},
    connectors: {connect, drag},
  } = useNode()
  const [question, setQuestion] = useState(() => {
    const q = quizQuestions.entries.find((entry: any) => entry.id === questionId)
    return q?.entry
  })
  const [isCorrect, setIsCorrect] = useState<boolean | null>(null)
  const [showResult, setShowResult] = useState(false)
  const [modalOpen, setModalOpen] = useState(false)
  const clazz = useClassNames(enabled, {empty: false}, ['section', 'quiz-section'])

  useEffect(() => {
    const q = quizQuestions.entries.find((entry: any) => entry.id === questionId)
    setQuestion(q?.entry)

    setIsCorrect(null)
    setShowResult(false)
  }, [questionId])

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
    (newQuestionId: string) => {
      setProp(prps => {
        prps.questionId = newQuestionId
      })
      setModalOpen(false)
    },
    [setProp]
  )

  const renderQuestion = () => {
    if (question) {
      switch (question.interaction_type.slug) {
        case 'true-false':
          return <TrueFalseQuestion question={question} onAnswerChange={handleCheckAnswer} />
        case 'choice':
          return <MultipleChoiceQuestion question={question} onAnswerChange={handleCheckAnswer} />
        case 'matching':
          return <MatchingQuestion question={question} onAnswerChange={handleCheckAnswer} />
        default:
          return <Alert variant="error">Unsupported question type</Alert>
      }
    } else {
      return (
        <div className="quiz-section__empty">
          {enabled ? (
            <Button onClick={showModal} color="primary">
              Select a question
            </Button>
          ) : (
            <Text>No question has been selected</Text>
          )}
        </div>
      )
    }
  }

  return (
    <div
      className={clazz}
      ref={ref => {
        ref && connect(drag(ref))
      }}
      style={{width: WIDTH, height: HEIGHT}}
    >
      <div className="block-header">
        <IconQuizSolid size="x-small" inline={true} />
        <span className="block-header-title">Quiz</span>
      </div>
      {renderQuestion()}
      <Flex justifyItems="space-between" padding="small">
        <Flex.Item shouldGrow={true}>
          {showResult && (
            <Alert variant={isCorrect ? 'success' : 'error'} margin="0 small 0 0">
              {isCorrect ? 'Correct!' : 'Bzzzzt, try again.'}
            </Alert>
          )}
        </Flex.Item>
        <Button
          color="secondary"
          onClick={handleSubmit}
          interaction={!enabled && questionId ? 'enabled' : 'disabled'}
        >
          Submit
        </Button>
      </Flex>
      {enabled && (
        <QuizModal
          open={modalOpen}
          currentQuestionId={questionId}
          onClose={() => setModalOpen(false)}
          onSelect={handleSelectQuestion}
        />
      )}
    </div>
  )
}

QuizSection.craft = {
  displayName: 'Quiz Question',
  defaultProps: {
    questionId: undefined,
  },
  related: {
    sectionMenu: QuizSectionMenu,
  },
  custom: {
    isSection: true,
  },
}

export {QuizSection}
