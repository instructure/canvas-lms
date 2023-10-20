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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {List} from '@instructure/ui-list'
import {Heading} from '@instructure/ui-heading'
import {TruncateText} from '@instructure/ui-truncate-text'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'
import {outcomeShape} from './shapes'
import {IconCheckMarkIndeterminateLine} from '@instructure/ui-icons'

const I18n = useI18nScope('OutcomeManagement')

const OutcomeRemoveModal = ({
  outcomes,
  isOpen,
  onCloseHandler,
  onCleanupHandler,
  removeOutcomes,
  onRemoveLearningOutcomesHandler,
}) => {
  const {isCourse} = useCanvasContext()
  const removableLinkIds = Object.keys(outcomes).filter(linkId => outcomes[linkId].canUnlink)
  const nonRemovableLinkIds = Object.keys(outcomes).filter(linkId => !outcomes[linkId].canUnlink)
  const removableCount = removableLinkIds.length
  const nonRemovableCount = nonRemovableLinkIds.length
  const totalCount = removableCount + nonRemovableCount

  const onRemoveOutcomesHandler = () => {
    ;(async () => {
      await removeOutcomes(outcomes)
      onRemoveLearningOutcomesHandler(removableLinkIds)
    })()
    onCleanupHandler()
  }

  const generateOutcomesList = outcomeLinkIds => {
    // Groups outcomes by parent group
    const groups = {}
    for (const linkId of outcomeLinkIds) {
      const groupId = outcomes[linkId].parentGroupId
      groups[groupId] = groups[groupId]
        ? {
            ...groups[groupId],
            groupOutcomes: [...groups[groupId].groupOutcomes, linkId],
          }
        : {
            groupId,
            groupTitle: outcomes[linkId].parentGroupTitle,
            groupOutcomes: [linkId],
          }
    }

    return (
      <>
        {Object.values(groups)
          .sort((a, b) => a.groupTitle.localeCompare(b.groupTitle, ENV.LOCALE, {numeric: true}))
          .map(({groupTitle, groupId, groupOutcomes}) => (
            <View key={groupId}>
              <TruncateText position="middle">
                {I18n.t('From %{groupTitle}', {groupTitle})}
              </TruncateText>
              <List as="ul" size="medium" margin="0" isUnstyled={true}>
                {groupOutcomes
                  .sort((a, b) =>
                    outcomes[a].title.localeCompare(outcomes[b].title, ENV.LOCALE, {numeric: true})
                  )
                  .map(linkId => (
                    <List.Item size="medium" padding="0 0 0 x-small" key={linkId}>
                      <Flex>
                        <Flex.Item padding="0 xxx-small 0 0">
                          <div
                            style={{
                              display: 'inline-block',
                              transform: 'scale(0.75)',
                              height: '1em',
                            }}
                          >
                            <IconCheckMarkIndeterminateLine />
                          </div>
                        </Flex.Item>
                        <Flex.Item>
                          <TruncateText position="middle">{outcomes[linkId].title}</TruncateText>
                        </Flex.Item>
                      </Flex>
                    </List.Item>
                  ))}
              </List>
            </View>
          ))}
      </>
    )
  }

  let modalLabel, modalMessage
  let modalButtons = (
    <>
      <Button type="button" color="secondary" margin="0 x-small 0 0" onClick={onCloseHandler}>
        {I18n.t('Cancel')}
      </Button>
      <Button type="button" color="danger" margin="0 x-small 0 0" onClick={onRemoveOutcomesHandler}>
        {I18n.t(
          {
            one: 'Remove Outcome',
            other: 'Remove Outcomes',
          },
          {
            count: removableCount,
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
          other: 'Unable To Remove Outcomes',
        },
        {
          count: nonRemovableCount,
        }
      )
      modalMessage = isCourse
        ? I18n.t(
            {
              one: 'The outcome that you have selected cannot be removed because it is aligned to content in this course.',
              other:
                'The outcomes that you have selected cannot be removed because they are aligned to content in this course.',
            },
            {
              count: nonRemovableCount,
            }
          )
        : I18n.t(
            {
              one: 'The outcome that you have selected cannot be removed because it is aligned to content in this account.',
              other:
                'The outcomes that you have selected cannot be removed because they are aligned to content in this account.',
            },
            {
              count: nonRemovableCount,
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
        totalCount,
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
        other: 'Remove Outcomes?',
      },
      {
        count: removableCount,
      }
    )
    modalMessage = isCourse
      ? I18n.t(
          {
            one: 'Are you sure that you want to remove this outcome from this course?',
            other: 'Are you sure that you want to remove these %{count} outcomes from this course?',
          },
          {
            count: removableCount,
          }
        )
      : I18n.t(
          {
            one: 'Are you sure that you want to remove this outcome from this account?',
            other:
              'Are you sure that you want to remove these %{count} outcomes from this account?',
          },
          {
            count: removableCount,
          }
        )
  }

  return (
    <Modal
      size="small"
      label={modalLabel}
      open={isOpen}
      shouldReturnFocus={true}
      onDismiss={onCloseHandler}
      shouldCloseOnDocumentClick={false}
      data-testid="outcome-management-remove-modal"
    >
      <Modal.Body overflow="scroll">
        <View as="div">
          <Text size="medium">{modalMessage}</Text>
        </View>
        <View as="div" maxHeight="16rem" tabIndex={removableCount > 10 ? '0' : '-1'}>
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
  onCloseHandler: PropTypes.func.isRequired,
  onCleanupHandler: PropTypes.func.isRequired,
  removeOutcomes: PropTypes.func.isRequired,
  onRemoveLearningOutcomesHandler: PropTypes.func,
}

OutcomeRemoveModal.defaultProps = {
  onRemoveLearningOutcomesHandler: () => {},
}

export default OutcomeRemoveModal
