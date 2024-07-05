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

import React, {useCallback, useEffect, useRef, useState} from 'react'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {quizQuestions} from '../../../../assets/data/quizQuestions'

type QuizModalProps = {
  open: boolean
  currentQuestionId: string | undefined
  onClose: () => void
  onSelect: (questionId: string) => void
}

const QuizModal = ({open, currentQuestionId, onClose, onSelect}: QuizModalProps) => {
  const [questionId, setQuestionId] = useState<string | undefined>(currentQuestionId)
  const parser = useRef(new DOMParser())

  useEffect(() => {
    if (!questionId && quizQuestions.entries.length > 0) {
      setQuestionId(quizQuestions.entries[0].id)
    }
  }, [questionId])

  const handleQuestionChange = useCallback(
    (
      _event: React.SyntheticEvent,
      data: {
        value?: string | number
        id?: string
      }
    ) => {
      setQuestionId(data.value as string)
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
        <SimpleSelect
          renderLabel="Select a question"
          assistiveText="Use arrow keys to navigate options"
          onChange={handleQuestionChange}
          value={questionId}
        >
          {quizQuestions.entries.map((question: any) => {
            const qbodydoc = parser.current.parseFromString(question.entry.item_body, 'text/html')
            return (
              <SimpleSelect.Option id={question.id} key={question.id} value={question.id}>
                {qbodydoc.body.textContent as string}
              </SimpleSelect.Option>
            )
          })}
        </SimpleSelect>
      </Modal.Body>
      <Modal.Footer>
        <Button color="secondary" onClick={onClose}>
          Cancel
        </Button>
        <Button
          onClick={handleChooseQuestion}
          color="primary"
          interaction={questionId ? 'enabled' : 'disabled'}
          margin="0 0 0 x-small"
        >
          Add to Section
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export {QuizModal}
