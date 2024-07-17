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
import {useEditor, useNode, type Node} from '@craftjs/core'
import {SectionMenu, type SectionMenuProps} from '../../../editor/SectionMenu'
import {QuizModal} from './QuizModal'

const QuizSectionMenu = ({onAddSection}: SectionMenuProps) => {
  const {actions} = useEditor()
  const {
    actions: {setProp},
    props,
  } = useNode(node => ({
    props: node.data.props,
  }))
  const [modalOpen, setModalOpen] = useState(false)

  const handleCloseModal = useCallback(() => {
    setModalOpen(false)
  }, [])

  const handleEditSection = useCallback((_node: Node) => {
    setModalOpen(true)
  }, [])

  const handleSelectQuestion = useCallback(
    (newQuestionId: string) => {
      setProp(prps => {
        prps.questionId = newQuestionId
      })
    },
    [setProp]
  )

  return (
    <>
      <SectionMenu onEditSection={handleEditSection} onAddSection={onAddSection} />
      <QuizModal
        open={modalOpen}
        currentQuestionId={props.questionId}
        onClose={handleCloseModal}
        onSelect={handleSelectQuestion}
      />
    </>
  )
}

export {QuizSectionMenu}
