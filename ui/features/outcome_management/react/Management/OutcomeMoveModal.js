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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import TargetGroupSelector from '../shared/TargetGroupSelector'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {MOVE_OUTCOME_LINKS} from '@canvas/outcomes/graphql/Management'
import {useMutation} from 'react-apollo'
import {outcomeShape} from './shapes'

const I18n = useI18nScope('OutcomeMoveModal')

const OutcomeMoveModal = ({
  outcomes,
  isOpen,
  onCloseHandler,
  onCleanupHandler,
  onSuccess,
  initialTargetGroup,
}) => {
  const [targetGroup, setTargetGroup] = useState(initialTargetGroup)
  const [targetAncestorsIds, setTargetAncestorsIds] = useState([])
  const count = Object.keys(outcomes).length
  const outcomeTitle = Object.values(outcomes)[0]?.title
  const [moveOutcomeLinks] = useMutation(MOVE_OUTCOME_LINKS)

  const disableSaveButton =
    !targetGroup || (count === 1 && Object.values(outcomes)[0].parentGroupId === targetGroup.id)
  const onMoveOutcomesHandler = () => {
    ;(async () => {
      try {
        const result = await moveOutcomeLinks({
          variables: {
            input: {
              groupId: targetGroup.id,
              outcomeLinkIds: Object.keys(outcomes),
            },
          },
        })
        const movedLinks = result.data?.moveOutcomeLinks?.movedOutcomeLinks
        const errorMessage = result.data?.moveOutcomeLinks?.errors?.[0]?.message
        if (movedLinks.length === 0) throw new Error(errorMessage)
        if (movedLinks.length !== count) throw new Error()

        onSuccess({
          movedOutcomeLinkIds: movedLinks.map(ct => ct._id),
          groupId: targetGroup.id,
          targetAncestorsIds,
        })

        showFlashAlert({
          message: I18n.t(
            {
              one: '"%{outcomeTitle}" has been moved to "%{newGroupTitle}".',
              other: '%{count} outcomes have been moved to "%{newGroupTitle}".',
            },
            {
              newGroupTitle: targetGroup.name,
              outcomeTitle,
              count,
            }
          ),
          type: 'success',
        })
      } catch (err) {
        showFlashAlert({
          message: I18n.t(
            {
              one: 'An error occurred while moving this outcome. Please try again.',
              other: 'An error occurred while moving these outcomes. Please try again.',
            },
            {
              count,
            }
          ),
          type: 'error',
        })
      }
    })()
    onCleanupHandler()
  }

  return (
    <Modal
      label={I18n.t(
        {
          one: 'Move "%{outcomeTitle}"?',
          other: 'Move %{count} Outcomes?',
        },
        {
          outcomeTitle,
          count,
        }
      )}
      size="medium"
      overflow="scroll"
      open={isOpen}
      onDismiss={onCloseHandler}
      shouldReturnFocus={true}
      shouldCloseOnDocumentClick={false}
    >
      <Modal.Body>
        <View as="div" maxHeight="450px" height="450px" position="static">
          <Text size="medium" weight="bold">
            {I18n.t(
              {
                one: 'Where would you like to move this outcome?',
                other: 'Where would you like to move these outcomes?',
              },
              {
                count,
              }
            )}
          </Text>
          <TargetGroupSelector
            // eslint-disable-next-line @typescript-eslint/no-shadow
            setTargetGroup={({targetGroup, targetAncestorsIds}) => {
              setTargetGroup(targetGroup)
              setTargetAncestorsIds(targetAncestorsIds)
            }}
            starterGroupId={initialTargetGroup.id}
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
          disabled={disableSaveButton}
          onClick={onMoveOutcomesHandler}
          data-testid="outcome-management-move-modal-move-button"
        >
          {I18n.t('Move')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

OutcomeMoveModal.propTypes = {
  outcomes: PropTypes.objectOf(outcomeShape).isRequired,
  isOpen: PropTypes.bool.isRequired,
  onCloseHandler: PropTypes.func.isRequired,
  onCleanupHandler: PropTypes.func.isRequired,
  initialTargetGroup: PropTypes.shape({
    id: PropTypes.string.isRequired,
    name: PropTypes.string.isRequired,
  }).isRequired,
  onSuccess: PropTypes.func,
}

OutcomeMoveModal.defaultProps = {
  onSuccess: () => {},
}

export default OutcomeMoveModal
