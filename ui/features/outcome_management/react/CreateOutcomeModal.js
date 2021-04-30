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
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {Mask} from '@instructure/ui-overlays'
import {ApplyTheme} from '@instructure/ui-themeable'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import useInput from '@canvas/outcomes/react/hooks/useInput'
import useRCE from './hooks/useRCE'
import {titleValidator, displayNameValidator} from '../validators/outcomeValidators'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {
  createOutcome,
  SET_OUTCOME_FRIENDLY_DESCRIPTION_MUTATION
} from '@canvas/outcomes/graphql/Management'
import TreeBrowser from './Management/TreeBrowser'
import {useManageOutcomes} from '@canvas/outcomes/react/treeBrowser'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'
import {useMutation} from 'react-apollo'

const CreateOutcomeModal = ({isOpen, onCloseHandler}) => {
  const {contextType, contextId} = useCanvasContext()
  const [title, titleChangeHandler] = useInput()
  const [displayName, displayNameChangeHandler] = useInput()
  const [altDescription, altDescriptionChangeHandler] = useInput()
  const [setRCERef, getRCECode, setRCECode] = useRCE()
  const [showTitleError, setShowTitleError] = useState(false)
  const [setOutcomeFriendlyDescription] = useMutation(SET_OUTCOME_FRIENDLY_DESCRIPTION_MUTATION)
  const {
    error,
    isLoading,
    collections,
    queryCollections,
    rootId,
    selectedGroupId
  } = useManageOutcomes()

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
    setRCECode('')
    onCloseHandler()
  }

  const onCreateOutcomeHandler = () => {
    ;(async () => {
      try {
        const result = await createOutcome(contextType, contextId, selectedGroupId, {
          title,
          description: getRCECode(),
          display_name: displayName
        })
        if (result.status === 200 && altDescription) {
          const altDescriptionResult = await setOutcomeFriendlyDescription({
            variables: {
              input: {
                outcomeId: result.data.outcome.id,
                description: altDescription,
                contextId,
                contextType
              }
            }
          })
          if (altDescriptionResult.data?.setFriendlyDescription?.errors) throw new Error()
        }
        showFlashAlert({
          message: I18n.t('Outcome "%{title}" was successfully created', {title}),
          type: 'success'
        })
      } catch (err) {
        showFlashAlert({
          message: err.message
            ? I18n.t('An error occurred while creating this outcome: %{message}', {
                message: err.message
              })
            : I18n.t('An error occurred while creating this outcome.'),
          type: 'error'
        })
      }
    })()
    closeModal()
  }

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
          <View as="div" padding="small 0 0">
            <TextArea size="medium" label={I18n.t('Description')} textareaRef={setRCERef} />
          </View>
          <View as="div" padding="small 0">
            <TextArea
              size="medium"
              height="8rem"
              maxHeight="10rem"
              value={altDescription}
              placeholder={I18n.t('Enter your alternate description here')}
              label={I18n.t('Alternate description (for parent/student display)')}
              onChange={altDescriptionChangeHandler}
            />
          </View>
          <View as="div" padding="x-small 0 0">
            <Text size="medium" weight="bold">
              {I18n.t('Location')}
            </Text>
            <View as="div" padding="small 0">
              {isLoading ? (
                <View
                  as="div"
                  textAlign="center"
                  padding="medium 0"
                  margin="0 auto"
                  data-testid="loading"
                >
                  <Spinner renderTitle={I18n.t('Loading')} size="medium" />
                </View>
              ) : error ? (
                <Text color="danger" data-testid="loading-error">
                  {contextType === 'Course'
                    ? I18n.t('An error occurred while loading course outcomes: %{error}', {error})
                    : I18n.t('An error occurred while loading account outcomes: %{error}', {error})}
                </Text>
              ) : (
                <TreeBrowser
                  selectionType="single"
                  onCollectionToggle={queryCollections}
                  collections={collections}
                  rootId={rootId}
                />
              )}
            </View>
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
            interaction={
              !invalidTitle && !invalidDisplayName && selectedGroupId ? 'enabled' : 'disabled'
            }
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
