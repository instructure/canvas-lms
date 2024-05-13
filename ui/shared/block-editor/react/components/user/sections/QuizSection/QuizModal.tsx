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
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {quizQuestions} from '../../../../assets/data/quizQuestions'

type QuizModalProps = {
  open: boolean
  currentQuestionId: string | undefined
  onClose: () => void
  onSelect: (questionId: string) => void
}

const QuizModal = ({open, currentQuestionId, onClose, onSelect}: QuizModalProps) => {
  const [questionId, setQuestionId] = useState<string | undefined>(currentQuestionId)

  const handleQuestionChange = useCallback(
    (_event: React.ChangeEvent<HTMLInputElement>, value: string) => {
      setQuestionId(value)
    },
    []
  )

  const handleChooseQuestion = useCallback(() => {
    if (!questionId) return
    onSelect(questionId)
    onClose()
  }, [onClose, onSelect, questionId])

  return (
    <Modal open={open} label="Select a question" onDismiss={onClose}>
      <Modal.Header>
        <Heading>Select a question</Heading>
        <CloseButton placement="end" onClick={onClose} screenReaderLabel="Close" />
      </Modal.Header>
      <Modal.Body>
        <RadioInputGroup
          description="Select a question"
          onChange={handleQuestionChange}
          name="level"
          size="small"
          value={questionId}
        >
          {quizQuestions.entries.map((question: any) => {
            return (
              <RadioInput
                key={question.id}
                value={question.id}
                label={
                  <div
                    className="question-option"
                    dangerouslySetInnerHTML={{__html: question.entry.item_body}}
                  />
                }
              />
            )
          })}
        </RadioInputGroup>
      </Modal.Body>
      <Modal.Footer>
        <Button color="secondary" onClick={onClose}>
          Cancel
        </Button>
        <Button
          onClick={handleChooseQuestion}
          color="primary"
          interaction={questionId ? 'enabled' : 'disabled'}
        >
          Add to Section
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export {QuizModal}
