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
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {type GlobalEnv} from '@canvas/global/env/GlobalEnv.d'
import {useScope as createI18nScope} from '@canvas/i18n'
import QuizSelect from './QuizSelect'
import QuestionSelect from './QuestionSelect'
import {type QuestionProps} from './types'

const I18n = createI18nScope('block-editor')
declare const ENV: GlobalEnv

type QuizModalProps = {
  open: boolean
  onClose: () => void
  onSelect: (question: QuestionProps) => void
}

const QuizModal = ({open, onClose, onSelect}: QuizModalProps) => {
  // @ts-expect-error
  const [questions, setQuestions] = useState<QuestionProps | undefined>(null)
  // @ts-expect-error
  const [question, setQuestion] = useState<QuestionProps | undefined>(null)
  const [quizId, setQuizId] = useState<string | null>(null)
  const [quizTitle, setQuizTitle] = useState<string | null>(null)

  useEffect(() => {
    setQuestion(undefined)
    setQuizId(null)
    setQuizTitle(null)
  }, [])

  const closeModal = useCallback(() => {
    onClose()
    setQuestion(undefined)
    setQuizId(null)
    setQuizTitle(null)
  }, [onClose])

  const handleQuestionSelect = useCallback((newQuestion: QuestionProps) => {
    setQuestion(newQuestion)
  }, [])

  const onSubmit = useCallback(() => {
    if (question) {
      onSelect(question)
    }
  }, [question, onSelect])

  const handleQuizSelect = useCallback((quiz: {id: string; title: string}) => {
    setQuizId(quiz.id)
    setQuizTitle(quiz.title)
    setQuestion(undefined)
    doFetchApi({
      path: `/api/quiz/v1/courses/${ENV.COURSE_ID}/quizzes/${quiz.id}/items`,
    })
      .then((response: any) => {
        setQuestions(response.json)
      })
      .catch(() => showFlashError(I18n.t("Couldn't load quiz items")))
  }, [])

  return (
    <Modal open={open} label={I18n.t('Select a question')} size="large" onDismiss={onClose}>
      <Modal.Header>
        <Heading>{quizTitle || I18n.t('Select a Quiz')}</Heading>
        <CloseButton
          placement="end"
          onClick={closeModal}
          screenReaderLabel={I18n.t('Close')}
          data-testid="close-modal-button"
        />
      </Modal.Header>
      <Modal.Body>
        {quizId ? (
          // @ts-expect-error
          <QuestionSelect questions={questions} onSelect={handleQuestionSelect} />
        ) : (
          <QuizSelect onSelect={handleQuizSelect} />
        )}
      </Modal.Body>
      <Modal.Footer>
        <Button color="secondary" onClick={closeModal}>
          {I18n.t('Cancel')}
        </Button>
        <Button
          onClick={onSubmit}
          color="primary"
          interaction={question ? 'enabled' : 'disabled'}
          margin="0 0 0 x-small"
        >
          {quizId ? I18n.t('Insert') : I18n.t('Next')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export {QuizModal}
