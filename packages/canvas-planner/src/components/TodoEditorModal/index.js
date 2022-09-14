/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React, {useEffect} from 'react'
import {CloseButton} from '@instructure/ui-buttons'
import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import PropTypes from 'prop-types'
import formatMessage from '../../format-message'
import {UpdateItemTray as UpdateItemForm} from '../UpdateItemTray'
import {alert} from '../../utilities/alertUtils'

export default function TodoEditorModal({
  locale,
  timeZone,
  todoItem,
  courses,
  onEdit,
  onClose,
  savePlannerItem,
  deletePlannerItem
}) {
  // tells dynamic-ui what just happened via onEdit/onClose
  useEffect(() => {
    if (todoItem) {
      onEdit() // tell dynamic-ui we've started editing
    }
  }, [onEdit, todoItem])

  const handleSavePlannerItem = plannerItem => {
    savePlannerItem(plannerItem)
      .then(onClose)
      .catch(() =>
        alert(formatMessage('Failed saving changes on {name}.', {name: todoItem?.title}), true)
      )
  }

  const handleDeletePlannerItem = plannerItem => {
    deletePlannerItem(plannerItem)
      .then(onClose)
      .catch(() => alert(formatMessage('Failed to delete {name}.', {name: todoItem?.title}), true))
  }

  const getModalLabel = () => {
    if (todoItem?.title) {
      return formatMessage('Edit {title}', {title: todoItem.title})
    }
    return formatMessage('To Do')
  }

  return (
    <Modal
      data-testid="todo-editor-modal"
      label={getModalLabel()}
      size="auto"
      theme={{autoMinWidth: '25em'}}
      open={!!todoItem}
      onDismiss={onClose}
      // clicking the calendar closes the Modal if we do not set this to false
      shouldCloseOnDocumentClick={false}
    >
      <Modal.Header>
        <Heading>{getModalLabel()}</Heading>
        <CloseButton
          data-testid="close-editor-modal"
          placement="end"
          onClick={onClose}
          screenReaderLabel={formatMessage('Close')}
        />
      </Modal.Header>
      <Modal.Body padding="none">
        <UpdateItemForm
          locale={locale}
          timeZone={timeZone}
          noteItem={todoItem}
          onSavePlannerItem={handleSavePlannerItem}
          onDeletePlannerItem={handleDeletePlannerItem}
          courses={courses || []}
        />
      </Modal.Body>
    </Modal>
  )
}
TodoEditorModal.propTypes = {
  locale: PropTypes.string.isRequired,
  timeZone: PropTypes.string.isRequired,
  todoItem: PropTypes.object,
  courses: PropTypes.arrayOf(PropTypes.object).isRequired,
  onEdit: PropTypes.func.isRequired,
  onClose: PropTypes.func.isRequired,
  savePlannerItem: PropTypes.func.isRequired,
  deletePlannerItem: PropTypes.func.isRequired
}
