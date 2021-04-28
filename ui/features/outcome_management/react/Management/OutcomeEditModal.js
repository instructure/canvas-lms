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

import React from 'react'
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
import useRCE from '../hooks/useRCE'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {updateOutcome} from '@canvas/outcomes/graphql/Management'

const OutcomeEditModal = ({outcome, isOpen, onCloseHandler}) => {
  const [title, titleChangeHandler, titleChanged] = useInput(outcome.title)
  const [displayName, displayNameChangeHandler, displayNameChanged] = useInput(outcome.displayName)
  const [description] = useInput(outcome.description)
  const [setRCERef, getRCECode] = useRCE()

  const invalidTitle = !title.trim().length
    ? I18n.t('Cannot be blank')
    : title.length > 255
    ? I18n.t('Must be 255 characters or less')
    : null

  const invalidDisplayName =
    displayName.length > 255 ? I18n.t('Must be 255 characters or less') : null

  const onUpdateOutcomeHandler = () => {
    ;(async () => {
      const descriptionRCE = getRCECode()
      const updatedOutcome = {}
      if (title && titleChanged) updatedOutcome.title = title
      if (descriptionRCE && descriptionRCE !== description)
        updatedOutcome.description = descriptionRCE
      if (displayName && displayNameChanged) updatedOutcome.display_name = displayName

      try {
        const result = await updateOutcome(outcome._id, updatedOutcome)
        if (result?.status === 200) {
          showFlashAlert({
            message: I18n.t('This outcome was successfully updated.'),
            type: 'success'
          })
        } else {
          throw Error()
        }
      } catch (err) {
        showFlashAlert({
          message: err.message
            ? I18n.t('An error occurred while updating this outcome: %{message}', {
                message: err.message
              })
            : I18n.t('An error occurred while updating this outcome.'),
          type: 'error'
        })
      }
    })()
    onCloseHandler()
  }

  return (
    <ApplyTheme theme={{[Mask.theme]: {zIndex: '1000'}}}>
      <Modal
        size="medium"
        label={I18n.t('Edit Outcome')}
        open={isOpen}
        shouldReturnFocus
        onDismiss={onCloseHandler}
        shouldCloseOnDocumentClick={false}
      >
        <Modal.Body>
          <Flex as="div" alignItems="start" padding="small 0" height="7rem">
            <Flex.Item size="50%" padding="0 xx-small 0 0">
              <TextInput
                type="text"
                size="medium"
                value={title}
                messages={invalidTitle ? [{text: invalidTitle, type: 'error'}] : []}
                renderLabel={I18n.t('Name')}
                onChange={titleChangeHandler}
              />
            </Flex.Item>
            <Flex.Item size="50%" padding="0 0 0 xx-small">
              <TextInput
                type="text"
                size="medium"
                value={displayName}
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
          <Button type="button" color="secondary" margin="0 x-small 0 0" onClick={onCloseHandler}>
            {I18n.t('Cancel')}
          </Button>
          <Button
            type="button"
            color="primary"
            margin="0 x-small 0 0"
            interaction={!invalidTitle && !invalidDisplayName ? 'enabled' : 'disabled'}
            onClick={onUpdateOutcomeHandler}
          >
            {I18n.t('Save')}
          </Button>
        </Modal.Footer>
      </Modal>
    </ApplyTheme>
  )
}

OutcomeEditModal.propTypes = {
  outcome: PropTypes.shape({
    _id: PropTypes.string.isRequired,
    title: PropTypes.string.isRequired,
    description: PropTypes.string,
    displayName: PropTypes.string
  }).isRequired,
  isOpen: PropTypes.bool.isRequired,
  onCloseHandler: PropTypes.func.isRequired
}

export default OutcomeEditModal
