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

import React, {useState} from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!FindOutcomesModal'
import {TextInput} from '@instructure/ui-text-input'
import {TextArea} from '@instructure/ui-text-area'
import {View} from '@instructure/ui-view'
import {Button} from '@instructure/ui-buttons'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {outcomeGroupShape} from './shapes'
import {updateOutcomeGroup} from '@canvas/outcomes/graphql/Management'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'

const EditGroupModal = ({outcomeGroup, isOpen, onCloseHandler}) => {
  const {contextType, contextId} = useCanvasContext()
  const [title, setTitle] = useState(outcomeGroup.title)
  const [description, setDescription] = useState(outcomeGroup.description)
  const [saving, setSaving] = useState(false)

  const errorMessage = message => (message ? [{text: message, type: 'error'}] : null)

  const titleError = !title.trim().length
    ? I18n.t('Missing required title')
    : title.length > 255
    ? I18n.t('Must be 255 characters or less')
    : null

  const titleChangeHandler = (_event, value) => {
    setTitle(value)
  }

  const descriptionChangeHandler = event => {
    setDescription(event.target.value)
  }

  const onConfirmHandler = async _ => {
    setSaving(true)
    const group = {_id: outcomeGroup._id, title, description}

    try {
      const result = await updateOutcomeGroup(contextType, contextId, group)
      if (result?.status === 200) {
        onCloseHandler()
        showFlashAlert({
          type: 'success',
          message: I18n.t('The group %{title} was successfully updated.', {title})
        })
      } else {
        throw Error()
      }
    } catch (err) {
      showFlashAlert({
        type: 'error',
        message: I18n.t('An error occurred while updating the group: %{message}', {
          message: err.message
        })
      })
    }

    setSaving(false)
  }

  return (
    <Modal label={I18n.t('Edit Group')} open={isOpen} onDismiss={onCloseHandler} size="medium">
      <Modal.Body>
        <View as="div" padding="0">
          <TextInput
            type="text"
            size="medium"
            value={title}
            renderLabel={I18n.t('Group Name')}
            onChange={titleChangeHandler}
            messages={errorMessage(titleError)}
          />
        </View>
        <View as="div" padding="medium 0">
          <TextArea
            size="medium"
            value={description}
            label={I18n.t('Group Description')}
            placeholder={I18n.t('Enter your description')}
            onChange={descriptionChangeHandler}
          />
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={onCloseHandler}>{I18n.t('Cancel')}</Button>
        &nbsp;
        <Button
          onClick={onConfirmHandler}
          variant="primary"
          interaction={titleError || saving ? 'disabled' : 'enabled'}
        >
          {I18n.t('Save')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

EditGroupModal.propTypes = {
  outcomeGroup: outcomeGroupShape.isRequired,
  isOpen: PropTypes.bool.isRequired,
  onCloseHandler: PropTypes.func.isRequired
}

export default EditGroupModal
