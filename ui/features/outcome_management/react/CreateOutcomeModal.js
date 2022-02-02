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

import React, {useState, useEffect} from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!OutcomeManagement'
import {TextInput} from '@instructure/ui-text-input'
import {TextArea} from '@instructure/ui-text-area'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {Mask} from '@instructure/ui-overlays'
import {ApplyTheme} from '@instructure/ui-themeable'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import useInput from '@canvas/outcomes/react/hooks/useInput'
import TargetGroupSelector from './shared/TargetGroupSelector'
import {titleValidator, displayNameValidator} from '../validators/outcomeValidators'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {
  CREATE_LEARNING_OUTCOME,
  SET_OUTCOME_FRIENDLY_DESCRIPTION_MUTATION
} from '@canvas/outcomes/graphql/Management'
import {useManageOutcomes} from '@canvas/outcomes/react/treeBrowser'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'
import {useMutation} from 'react-apollo'
import OutcomesRceField from './shared/OutcomesRceField'
import ProficiencyCalculation, {
  defaultProficiencyCalculation
} from './MasteryCalculation/ProficiencyCalculation'
import useRatings, {
  defaultRatings,
  defaultMasteryPoints
} from '@canvas/outcomes/react/hooks/useRatings'
import {processRatingsAndMastery} from '@canvas/outcomes/react/helpers/ratingsHelpers'
import Ratings from './Management/Ratings'

const CreateOutcomeModal = ({isOpen, onCloseHandler, onSuccess, starterGroupId}) => {
  const {
    contextType,
    contextId,
    friendlyDescriptionFF,
    isMobileView,
    individualOutcomeRatingAndCalculationFF
  } = useCanvasContext()
  const [title, titleChangeHandler] = useInput()
  const [displayName, displayNameChangeHandler] = useInput()
  const [friendlyDescription, friendlyDescriptionChangeHandler] = useInput()
  const [description, setDescription] = useState('')
  const [showTitleError, setShowTitleError] = useState(false)
  const [setOutcomeFriendlyDescription] = useMutation(SET_OUTCOME_FRIENDLY_DESCRIPTION_MUTATION)
  const [createLearningOutcome] = useMutation(CREATE_LEARNING_OUTCOME)
  const {rootId, collections} = useManageOutcomes({
    collection: 'OutcomeManagementPanel',
    initialGroupId: starterGroupId
  })
  const {
    ratings,
    masteryPoints,
    setRatings,
    setMasteryPoints,
    hasError: proficiencyRatingsError
  } = useRatings({
    initialRatings: defaultRatings,
    initialMasteryPoints: defaultMasteryPoints
  })

  const [selectedGroup, setSelectedGroup] = useState(null)
  const [selectedGroupAncestorIds, setSelectedGroupAncestorIds] = useState([])
  const [proficiencyCalculation, setProficiencyCalculation] = useState(
    defaultProficiencyCalculation
  )
  const [proficiencyCalculationError, setProficiencyCalculationError] = useState(false)

  useEffect(() => {
    if (rootId && collections[rootId] && !selectedGroup) {
      setSelectedGroup(collections[rootId])
      setSelectedGroupAncestorIds([rootId])
    }
  }, [collections, rootId, selectedGroup, selectedGroupAncestorIds])

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

  const friendlyDescriptionMessages = []
  if (friendlyDescription.length > 255) {
    friendlyDescriptionMessages.push({
      text: I18n.t('Must be 255 characters or less'),
      type: 'error'
    })
  }

  const formValid =
    !invalidTitle &&
    !invalidDisplayName &&
    selectedGroup &&
    friendlyDescriptionMessages.length === 0 &&
    (individualOutcomeRatingAndCalculationFF
      ? !proficiencyCalculationError && !proficiencyRatingsError
      : true)

  const updateProficiencyCalculation = (calculationMethodKey, calculationInt) =>
    setProficiencyCalculation({calculationMethod: calculationMethodKey, calculationInt})

  const onCreateOutcomeHandler = () => {
    ;(async () => {
      try {
        const input = {
          groupId: selectedGroup.id,
          title,
          displayName,
          description
        }
        if (individualOutcomeRatingAndCalculationFF) {
          input.calculationMethod = proficiencyCalculation.calculationMethod
          input.calculationInt = proficiencyCalculation.calculationInt
          const {masteryPoints: inputMasteryPoints, ratings: inputRatings} =
            processRatingsAndMastery(ratings, masteryPoints.value)
          input.masteryPoints = inputMasteryPoints
          input.ratings = inputRatings
        }
        const createLearningOutcomeResult = await createLearningOutcome({
          variables: {
            input
          }
        })

        const outcomeId =
          createLearningOutcomeResult.data?.createLearningOutcome?.learningOutcome?._id
        const errorMessage =
          createLearningOutcomeResult.data?.createLearningOutcome?.errors?.[0]?.message

        if (!outcomeId) throw new Error(errorMessage)

        if (friendlyDescriptionFF && friendlyDescription) {
          await setOutcomeFriendlyDescription({
            variables: {
              input: {
                outcomeId,
                description: friendlyDescription,
                contextId,
                contextType
              }
            }
          })
        }
        onSuccess({selectedGroupAncestorIds})
        // resetting selectedGroup to null otherwise it will be maintained
        // and will cause the group to not be loaded in the GroupSelectedDrillDown
        // when opening the create modal again
        setSelectedGroup(null)

        showFlashAlert({
          message: I18n.t('"%{title}" was successfully created.', {title}),
          type: 'success'
        })
      } catch (err) {
        showFlashAlert({
          message: I18n.t('An error occurred while creating this outcome. Please try again.'),
          type: 'error'
        })
      }
    })()
    closeModal()
  }

  const titleInput = (
    <TextInput
      type="text"
      size="medium"
      value={title}
      placeholder={I18n.t('Enter name or code')}
      messages={invalidTitle && showTitleError ? [{text: invalidTitle, type: 'error'}] : []}
      renderLabel={I18n.t('Name')}
      onChange={changeTitle}
    />
  )

  const displayNameInput = (
    <TextInput
      type="text"
      size="medium"
      value={displayName}
      placeholder={I18n.t('Create a friendly display name')}
      messages={invalidDisplayName ? [{text: invalidDisplayName, type: 'error'}] : []}
      renderLabel={I18n.t('Friendly Name')}
      onChange={displayNameChangeHandler}
    />
  )

  return (
    <ApplyTheme theme={{[Mask.theme]: {zIndex: '1000'}}}>
      <Modal
        size={!isMobileView ? 'large' : 'fullscreen'}
        label={I18n.t('Create Outcome')}
        open={isOpen}
        shouldReturnFocus
        onDismiss={closeModal}
        shouldCloseOnDocumentClick={false}
        data-testid="createOutcomeModal"
      >
        <Modal.Body>
          {!isMobileView ? (
            <Flex as="div" alignItems="start" padding="small 0" height="7rem">
              <Flex.Item size="50%" padding="0 xx-small 0 0">
                {titleInput}
              </Flex.Item>
              <Flex.Item size="50%" padding="0 0 0 xx-small">
                {displayNameInput}
              </Flex.Item>
            </Flex>
          ) : (
            <>
              <View as="div" padding="small 0">
                {titleInput}
              </View>
              <View as="div" padding="small 0">
                {displayNameInput}
              </View>
            </>
          )}
          <View as="div" padding="small 0 0">
            <Text weight="bold">{I18n.t('Description')}</Text> <br />
            {isOpen && <OutcomesRceField onChangeHandler={setDescription} />}
          </View>
          {friendlyDescriptionFF && (
            <View as="div" padding="small 0">
              <TextArea
                size="medium"
                height="8rem"
                maxHeight="10rem"
                value={friendlyDescription}
                placeholder={I18n.t('Enter your friendly description here')}
                label={I18n.t('Friendly description (for parent/student display)')}
                onChange={friendlyDescriptionChangeHandler}
                messages={friendlyDescriptionMessages}
              />
            </View>
          )}
          {individualOutcomeRatingAndCalculationFF && (
            <View as="div" padding="small 0 0">
              <Ratings
                ratings={ratings}
                onChangeRatings={setRatings}
                masteryPoints={masteryPoints}
                onChangeMasteryPoints={setMasteryPoints}
                canManage
              />
              <View as="div" minHeight="14rem">
                <hr style={{margin: '1rem 0 0'}} />
                <ProficiencyCalculation
                  update={updateProficiencyCalculation}
                  setError={setProficiencyCalculationError}
                  individualOutcome="edit"
                  canManage
                />
              </View>
            </View>
          )}
          <View as="div" padding="x-small 0 0">
            <Text size="medium" weight="bold">
              {isMobileView ? I18n.t('Select a location') : I18n.t('Location')}
            </Text>
            <TargetGroupSelector
              groupId={selectedGroup?.id}
              setTargetGroup={({targetGroup, targetAncestorsIds}) => {
                setSelectedGroupAncestorIds(targetAncestorsIds)
                setSelectedGroup(targetGroup)
              }}
              starterGroupId={starterGroupId}
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
            interaction={formValid ? 'enabled' : 'disabled'}
            onClick={onCreateOutcomeHandler}
          >
            {I18n.t('Create')}
          </Button>
        </Modal.Footer>
      </Modal>
    </ApplyTheme>
  )
}

CreateOutcomeModal.defaultProps = {
  onSuccess: () => {}
}

CreateOutcomeModal.propTypes = {
  isOpen: PropTypes.bool.isRequired,
  onCloseHandler: PropTypes.func.isRequired,
  onSuccess: PropTypes.func,
  starterGroupId: PropTypes.string
}

export default CreateOutcomeModal
