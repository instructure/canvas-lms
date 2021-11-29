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
import {Text} from '@instructure/ui-text'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Mask} from '@instructure/ui-overlays'
import {ApplyTheme} from '@instructure/ui-themeable'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import useInput from '@canvas/outcomes/react/hooks/useInput'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {titleValidator, displayNameValidator} from '../../validators/outcomeValidators'
import {
  UPDATE_LEARNING_OUTCOME,
  SET_OUTCOME_FRIENDLY_DESCRIPTION_MUTATION
} from '@canvas/outcomes/graphql/Management'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'
import {useMutation} from 'react-apollo'
import OutcomesRceField from '../shared/OutcomesRceField'

const OutcomeEditModal = ({outcome, isOpen, onCloseHandler}) => {
  const [title, titleChangeHandler, titleChanged] = useInput(outcome.title)
  const [displayName, displayNameChangeHandler, displayNameChanged] = useInput(
    outcome.displayName || ''
  )
  const [description, setDescription, descriptionChanged] = useInput(outcome.description || '')
  const [friendlyDescription, friendlyDescriptionChangeHandler, friendlyDescriptionChanged] =
    useInput(outcome.friendlyDescription?.description || '')
  const {contextType, contextId, friendlyDescriptionFF} = useCanvasContext()
  const [updateLearningOutcomeMutation] = useMutation(UPDATE_LEARNING_OUTCOME)
  const [setOutcomeFriendlyDescription] = useMutation(SET_OUTCOME_FRIENDLY_DESCRIPTION_MUTATION)
  let attributesEditable = {
    friendlyDescription: true
  }
  if (outcome.contextType === contextType && outcome.contextId?.toString() === contextId) {
    attributesEditable = {
      ...attributesEditable,
      title: true,
      displayName: true,
      description: true
    }
  }

  const invalidTitle = titleValidator(title)
  const invalidDisplayName = displayNameValidator(displayName)

  const friendlyDescriptionMessages = []
  if (friendlyDescriptionChanged && friendlyDescription.length > 255) {
    friendlyDescriptionMessages.push({
      text: I18n.t('Must be 255 characters or less'),
      type: 'error'
    })
  }
  const formValid = !(invalidTitle || invalidDisplayName || friendlyDescriptionMessages.length > 0)

  const onUpdateOutcomeHandler = () => {
    ;(async () => {
      try {
        const promises = []
        if (
          (title && titleChanged) ||
          (displayName && displayNameChanged) ||
          (description && descriptionChanged)
        ) {
          promises.push(
            updateLearningOutcomeMutation({
              variables: {
                input: {
                  id: outcome._id,
                  title,
                  displayName,
                  description
                }
              }
            })
          )
        }
        if (friendlyDescriptionFF && friendlyDescriptionChanged) {
          promises.push(
            setOutcomeFriendlyDescription({
              variables: {
                input: {
                  description: friendlyDescription,
                  contextId,
                  contextType,
                  outcomeId: outcome._id
                }
              }
            })
          )
        }

        await Promise.all(promises)

        showFlashAlert({
          message: I18n.t('"%{title}" was successfully updated.', {
            title
          }),
          type: 'success'
        })
      } catch (err) {
        showFlashAlert({
          message: I18n.t('An error occurred while editing this outcome. Please try again.'),
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
              {attributesEditable.title ? (
                <TextInput
                  type="text"
                  size="medium"
                  value={title}
                  messages={invalidTitle ? [{text: invalidTitle, type: 'error'}] : []}
                  renderLabel={I18n.t('Name')}
                  onChange={titleChangeHandler}
                  data-testid="name-input"
                />
              ) : (
                <View as="div">
                  <Text weight="bold">{I18n.t('Name')}</Text> <br />
                  <View as="div" margin="small 0 0">
                    <Text>{outcome.title}</Text>
                  </View>
                </View>
              )}
            </Flex.Item>
            <Flex.Item size="50%" padding="0 0 0 xx-small">
              {attributesEditable.displayName ? (
                <TextInput
                  type="text"
                  size="medium"
                  value={displayName}
                  messages={invalidDisplayName ? [{text: invalidDisplayName, type: 'error'}] : []}
                  renderLabel={I18n.t('Friendly Name')}
                  onChange={displayNameChangeHandler}
                  data-testid="display-name-input"
                />
              ) : (
                <View as="div">
                  <Text weight="bold">{I18n.t('Friendly Name')}</Text> <br />
                  <View as="div" margin="small 0 0">
                    <Text>{outcome.displayName}</Text>
                  </View>
                </View>
              )}
            </Flex.Item>
          </Flex>
          <View as="div" padding="small 0">
            {attributesEditable.description ? (
              <>
                <Text weight="bold">{I18n.t('Description')}</Text> <br />
                <OutcomesRceField onChangeHandler={setDescription} defaultContent={description} />
              </>
            ) : (
              <View as="div" data-testid="readonly-description">
                <Text weight="bold">{I18n.t('Description')}</Text> <br />
                <View as="div" margin="small 0 0">
                  <Text as="p" dangerouslySetInnerHTML={{__html: outcome.description}} />
                </View>
              </View>
            )}
          </View>
          {friendlyDescriptionFF && (
            <View as="div" padding="small 0">
              <TextArea
                autoGrow
                size="medium"
                height="8rem"
                maxHeight="8rem"
                value={friendlyDescription}
                label={I18n.t('Friendly description (for parent/student display)')}
                placeholder={I18n.t('Enter your friendly description here')}
                onChange={friendlyDescriptionChangeHandler}
                messages={friendlyDescriptionMessages}
                data-testid="friendly-description-input"
              />
            </View>
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button type="button" color="secondary" margin="0 x-small 0 0" onClick={onCloseHandler}>
            {I18n.t('Cancel')}
          </Button>
          <Button
            type="button"
            color="primary"
            margin="0 x-small 0 0"
            interaction={formValid ? 'enabled' : 'disabled'}
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
    displayName: PropTypes.string,
    contextId: PropTypes.string,
    contextType: PropTypes.string,
    friendlyDescription: PropTypes.shape({
      description: PropTypes.string.isRequired
    })
  }).isRequired,
  isOpen: PropTypes.bool.isRequired,
  onCloseHandler: PropTypes.func.isRequired
}

export default OutcomeEditModal
