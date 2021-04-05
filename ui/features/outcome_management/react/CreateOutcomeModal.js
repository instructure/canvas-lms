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
import I18n from 'i18n!OutcomeManagement'
import {TextInput} from '@instructure/ui-text-input'
import {TextArea} from '@instructure/ui-text-area'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Mask} from '@instructure/ui-overlays'
import {ApplyTheme} from '@instructure/ui-themeable'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import useInput from '@canvas/outcomes/react/hooks/useInput'
import useRCE from './hooks/useRCE'
import {
  titleValidator,
  displayNameValidator
} from '../validators/outcomeValidators'

const CreateOutcomeModal = ({isOpen, onCloseHandler}) => {
  const [title, titleChangeHandler] = useInput()
  const [displayName, displayNameChangeHandler] = useInput()
  const [description] = useInput()
  const [setRCERef] = useRCE()
  const [showTitleError, setShowTitleError] = useState(false)

  const invalidTitle = titleValidator(title)
  const invalidDisplayName = displayNameValidator(displayName)

  const changeTitle = event => {
    if (!showTitleError) setShowTitleError(true)
    titleChangeHandler(event)
  }

  const closeModal = () => {
    setShowTitleError(false)
    titleChangeHandler('')
    displayNameChangeHandler('')
    onCloseHandler()
  }

  const onCreateOutcomeHandler = () => closeModal()

  return (
    <ApplyTheme theme={{[Mask.theme]: {zIndex: '1000'}}}>
      <Modal
        size="large"
        label={I18n.t('Create Outcome')}
        open={isOpen}
        shouldReturnFocus
        onDismiss={closeModal}
        shouldCloseOnDocumentClick={false}
      >
        <Modal.Body>
          <Flex as="div" alignItems="start" padding="small 0" height="7rem">
            <Flex.Item size="50%" padding="0 xx-small 0 0">
              <TextInput
                type="text"
                size="medium"
                value={title}
                placeholder={I18n.t('Enter name or code')}
                messages={
                  invalidTitle && showTitleError ? [{text: invalidTitle, type: 'error'}] : []
                }
                renderLabel={I18n.t('Name')}
                onChange={changeTitle}
              />
            </Flex.Item>
            <Flex.Item size="50%" padding="0 0 0 xx-small">
              <TextInput
                type="text"
                size="medium"
                value={displayName}
                placeholder={I18n.t('Create a friendly display name')}
                messages={invalidDisplayName ? [{text: invalidDisplayName, type: 'error'}] : []}
                renderLabel={I18n.t('Friendly Name')}
                onChange={displayNameChangeHandler}
              />
            </Flex.Item>
          </Flex>
          <View as="div" padding="small 0">
            <TextArea
              size="medium"
              defaultValue={description}
              label={I18n.t('Description')}
              textareaRef={setRCERef}
            />
          </View>
        </Modal.Body>
        <Modal.Footer>
          <Button type="button" color="secondary" margin="0 x-small 0 0" onClick={closeModal}>
            {I18n.t('Cancel')}
          </Button>
          <Button
            type="button"
            color="primary"
            margin="0 x-small 0 0"
            interaction={!invalidTitle && !invalidDisplayName ? 'enabled' : 'disabled'}
            onClick={onCreateOutcomeHandler}
          >
            {I18n.t('Create')}
          </Button>
        </Modal.Footer>
      </Modal>
    </ApplyTheme>
  )
}

CreateOutcomeModal.propTypes = {
  isOpen: PropTypes.bool.isRequired,
  onCloseHandler: PropTypes.func.isRequired
}

export default CreateOutcomeModal
