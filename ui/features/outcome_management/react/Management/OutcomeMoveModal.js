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
import I18n from 'i18n!OutcomeMoveModal'
import {Text} from '@instructure/ui-text'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import TargetGroupSelector from '../shared/TargetGroupSelector'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {MOVE_OUTCOME_LINKS} from '@canvas/outcomes/graphql/Management'
import {useMutation} from 'react-apollo'
import {outcomeShape} from './shapes'

const OutcomeMoveModal = ({outcomes, isOpen, onCloseHandler, onCleanupHandler}) => {
  const [targetGroup, setTargetGroup] = useState(null)
  const count = Object.keys(outcomes).length
  const outcomeTitle = Object.values(outcomes)[0]?.title
  const [moveOutcomeLinks] = useMutation(MOVE_OUTCOME_LINKS)

  const onMoveOutcomesHandler = () => {
    ;(async () => {
      try {
        const result = await moveOutcomeLinks({
          variables: {
            input: {
              groupId: targetGroup.id,
              outcomeLinkIds: Object.keys(outcomes)
            }
          }
        })

        const movedOutcomeLinkIds = result.data?.moveOutcomeLinks?.movedOutcomeLinkIds
        const errorMessage = result.data?.moveOutcomeLinks?.errors?.[0]?.message
        if (movedOutcomeLinkIds.length === 0) throw new Error(errorMessage)
        if (movedOutcomeLinkIds.length !== count) throw new Error()

        showFlashAlert({
          message: I18n.t(
            {
              one: '"%{outcomeTitle}" has been moved to "%{newGroupTitle}".',
              other: '%{count} outcomes have been moved to "%{newGroupTitle}".'
            },
            {
              newGroupTitle: targetGroup.name,
              outcomeTitle,
              count
            }
          ),
          type: 'success'
        })
      } catch (err) {
        showFlashAlert({
          message: err.message
            ? I18n.t(
                {
                  one: 'An error occurred moving outcome "%{outcomeTitle}" to "%{newGroupTitle}": %{errorMessage}.',
                  other: 'An error occurred moving these outcomes: %{errorMessage}.'
                },
                {
                  newGroupTitle: targetGroup.name,
                  errorMessage: err.message,
                  outcomeTitle,
                  count
                }
              )
            : I18n.t(
                {
                  one: 'An error occurred moving outcome "%{outcomeTitle}" to "%{newGroupTitle}".',
                  other: 'An error occurred moving these outcomes.'
                },
                {
                  newGroupTitle: targetGroup.name,
                  outcomeTitle,
                  count
                }
              ),
          type: 'error'
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
          other: 'Move %{count} Outcomes?'
        },
        {
          outcomeTitle,
          count
        }
      )}
      size="medium"
      overflow="scroll"
      open={isOpen}
      onDismiss={onCloseHandler}
      shouldReturnFocus
      shouldCloseOnDocumentClick={false}
    >
      <Modal.Body>
        <View as="div" maxHeight="450px" height="450px" position="static">
          <Text size="medium" weight="bold">
            {I18n.t(
              {
                one: 'Where would you like to move this outcome?',
                other: 'Where would you like to move these outcomes?'
              },
              {
                count
              }
            )}
          </Text>
          <TargetGroupSelector setTargetGroup={setTargetGroup} />
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
          disabled={!targetGroup}
          onClick={onMoveOutcomesHandler}
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
  onCleanupHandler: PropTypes.func.isRequired
}

export default OutcomeMoveModal
