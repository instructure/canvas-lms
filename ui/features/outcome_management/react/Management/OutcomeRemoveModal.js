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
import {useMutation} from 'react-apollo'
import PropTypes from 'prop-types'
import I18n from 'i18n!OutcomeManagement'
import {Text} from '@instructure/ui-text'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {List} from '@instructure/ui-list'
import {Heading} from '@instructure/ui-heading'
import {TruncateText} from '@instructure/ui-truncate-text'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {DELETE_OUTCOME_LINKS} from '@canvas/outcomes/graphql/Management'
import {outcomeShape} from './shapes'

const OutcomeRemoveModal = ({outcomes, isOpen, onCloseHandler}) => {
  const {isCourse} = useCanvasContext()
  const removableLinkIds = Object.keys(outcomes).filter(linkId => outcomes[linkId].canUnlink)
  const nonRemovableLinkIds = Object.keys(outcomes).filter(linkId => !outcomes[linkId].canUnlink)
  const removableCount = removableLinkIds.length
  const nonRemovableCount = nonRemovableLinkIds.length
  const totalCount = removableCount + nonRemovableCount

  // Temp until OUT-4517 is closed
  const outcomeLinkId = totalCount === 1 ? Object.keys(outcomes)[0] : removableLinkIds[0]

  const [deleteOutcomeLinks] = useMutation(DELETE_OUTCOME_LINKS, {
    onCompleted: _data => {
      if (_data.deleteOutcomeLinks?.deletedOutcomeLinkIds.length === 0)
        throw new Error(_data.deleteOutcomeLinks?.errors?.[0]?.message)

      showFlashAlert({
        message: isCourse
          ? I18n.t('This outcome was successfully removed from this course.')
          : I18n.t('This outcome was successfully removed from this account.'),
        type: 'success'
      })
    },
    onError: _err => {
      _err.message = _err.message.match(/cannot be deleted because it is aligned to content/)
        ? I18n.t('Outcome cannot be removed because it is aligned to content')
        : _err.message
      showFlashAlert({
        message: _err.message
          ? I18n.t('An error occurred while removing the outcome: %{message}', {
              message: _err.message
            })
          : I18n.t('An error occurred while removing the outcome.'),
        type: 'error'
      })
    },
    variables: {
      ids: [outcomeLinkId]
    }
  })

  const onRemoveOutcomeHandler = () => {
    deleteOutcomeLinks()
    onCloseHandler()
  }

  const generateOutcomesList = outcomeLinkIds => (
    <List as="ul" size="medium" margin="0" isUnstyled>
      {outcomeLinkIds.map(linkId => (
        <List.Item size="medium" key={linkId}>
          <TruncateText>{outcomes[linkId].title}</TruncateText>
        </List.Item>
      ))}
    </List>
  )

  let modalLabel, modalMessage
  let modalButtons = (
    <>
      <Button type="button" color="secondary" margin="0 x-small 0 0" onClick={onCloseHandler}>
        {I18n.t('Cancel')}
      </Button>
      <Button type="button" color="danger" margin="0 x-small 0 0" onClick={onRemoveOutcomeHandler}>
        {I18n.t(
          {
            one: 'Remove Outcome',
            other: 'Remove Outcomes'
          },
          {
            count: removableCount
          }
        )}
      </Button>
    </>
  )
  if (nonRemovableCount > 0) {
    if (removableCount === 0) {
      modalLabel = I18n.t(
        {
          one: 'Unable To Remove Outcome',
          other: 'Unable To Remove Outcomes'
        },
        {
          count: nonRemovableCount
        }
      )
      modalMessage = isCourse
        ? I18n.t(
            {
              one: 'The outcome that you have selected cannot be removed because it is aligned to content in this course.',
              other:
                'The outcomes that you have selected cannot be removed because they are aligned to content in this course.'
            },
            {
              count: nonRemovableCount
            }
          )
        : I18n.t(
            {
              one: 'The outcome that you have selected cannot be removed because it is aligned to content in this account.',
              other:
                'The outcomes that you have selected cannot be removed because they are aligned to content in this account.'
            },
            {
              count: nonRemovableCount
            }
          )
      modalButtons = (
        <Button type="button" color="secondary" margin="0 x-small 0 0" onClick={onCloseHandler}>
          {I18n.t('OK')}
        </Button>
      )
    } else {
      modalLabel = I18n.t('Remove %{removableCount} out of %{totalCount} Outcomes?', {
        removableCount,
        totalCount
      })
      modalMessage = isCourse
        ? I18n.t(
            'Some of the outcomes that you have selected cannot be removed because they are aligned to content in this course. Do you want to proceed with removing the outcomes without alignments?'
          )
        : I18n.t(
            'Some of the outcomes that you have selected cannot be removed because they are aligned to content in this account. Do you want to proceed with removing the outcomes without alignments?'
          )
    }
  } else {
    modalLabel = I18n.t(
      {
        one: 'Remove Outcome?',
        other: 'Remove Outcomes?'
      },
      {
        count: removableCount
      }
    )
    modalMessage = isCourse
      ? I18n.t(
          {
            one: 'Are you sure that you want to remove this outcome from this course?',
            other: 'Are you sure that you want to remove these %{count} outcomes from this course?'
          },
          {
            count: removableCount
          }
        )
      : I18n.t(
          {
            one: 'Are you sure that you want to remove this outcome from this account?',
            other: 'Are you sure that you want to remove these %{count} outcomes from this account?'
          },
          {
            count: removableCount
          }
        )
  }

  return (
    <Modal
      size="small"
      label={modalLabel}
      open={isOpen}
      shouldReturnFocus
      onDismiss={onCloseHandler}
      shouldCloseOnDocumentClick={false}
    >
      <Modal.Body overflow="scroll">
        <View as="div">
          <Text size="medium">{modalMessage}</Text>
        </View>
        <View as="div" maxHeight="16rem">
          {nonRemovableCount > 0 && removableCount > 0 ? (
            <>
              <View as="div" padding="small 0 xx-small">
                <Heading level="h4">{I18n.t('Remove:')}</Heading>
              </View>
              {generateOutcomesList(removableLinkIds)}
              <View as="div" padding="small 0 xx-small">
                <Heading level="h4">{I18n.t('Cannot Remove:')}</Heading>
              </View>
              {generateOutcomesList(nonRemovableLinkIds)}
            </>
          ) : (
            <View as="div" padding={removableCount > 10 ? 'small 0 medium' : 'small 0 0'}>
              {generateOutcomesList(removableLinkIds)}
            </View>
          )}
        </View>
      </Modal.Body>
      <Modal.Footer>{modalButtons}</Modal.Footer>
    </Modal>
  )
}

OutcomeRemoveModal.propTypes = {
  outcomes: PropTypes.objectOf(outcomeShape).isRequired,
  isOpen: PropTypes.bool.isRequired,
  onCloseHandler: PropTypes.func.isRequired
}

export default OutcomeRemoveModal
