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
import {useNode, type Node} from '@craftjs/core'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconEditLine} from '@instructure/ui-icons'
import {type QuestionProps, type KnowledgeCheckSectionProps} from './types'
import {QuizModal} from './QuizModal'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

const KnowledgeCheckSectionToolbar = () => {
  const {
    actions: {setProp},
  } = useNode((n: Node) => ({
    props: n.data.props,
    node: n,
  }))
  const [modalOpen, setModalOpen] = useState(false)

  const handleCloseModal = useCallback(() => {
    setModalOpen(false)
  }, [])

  const handleSelectQuestion = useCallback(
    (question: QuestionProps) => {
      setProp((prps: KnowledgeCheckSectionProps) => {
        prps.id = question.id
        prps.entry = question.entry
      })
      setModalOpen(false)
    },
    [setProp],
  )

  return (
    <Flex gap="small">
      <IconButton
        size="small"
        withBackground={false}
        withBorder={false}
        screenReaderLabel={I18n.t('Edit Quiz')}
        title={I18n.t('Edit Quiz')}
        onClick={() => setModalOpen(true)}
        data-testid="edit-quiz-button"
      >
        <IconEditLine />
      </IconButton>

      <QuizModal open={modalOpen} onClose={handleCloseModal} onSelect={handleSelectQuestion} />
    </Flex>
  )
}

export {KnowledgeCheckSectionToolbar}
