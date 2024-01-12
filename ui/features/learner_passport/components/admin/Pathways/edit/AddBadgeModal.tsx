/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useCallback, useEffect, useState} from 'react'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import type {PathwayBadgeType} from '../../../types'

type AddBadgeModalProps = {
  allBadges: PathwayBadgeType[]
  open: boolean
  selectedBadgeId: string | null
  onClose: () => void
  onSave: (badgeId: string | null) => void
}

const AddBadgeModal = ({allBadges, open, selectedBadgeId, onClose, onSave}: AddBadgeModalProps) => {
  const [currSelectedId, setCurrSelectedId] = useState<string | null>(null)

  useEffect(() => {
    setCurrSelectedId(selectedBadgeId)
  }, [selectedBadgeId])

  const handleSelectBadge = useCallback(
    (badgeId: string | null) => {
      if (badgeId === currSelectedId || badgeId === null) {
        setCurrSelectedId(null)
      } else {
        const badge = allBadges.find(ach => ach.id === badgeId)
        if (badge) {
          setCurrSelectedId(badge.id)
        } else {
          setCurrSelectedId(null)
        }
      }
    },
    [allBadges, currSelectedId]
  )

  const handleBadgeClick = useCallback(
    (event: React.MouseEvent) => {
      const badgeId = event.currentTarget.getAttribute('data-badgeid')
      handleSelectBadge(badgeId)
    },
    [handleSelectBadge]
  )

  const handleBadgeKey = useCallback(
    (event: React.KeyboardEvent) => {
      if (event.key === 'Enter') {
        const badgeId = event.currentTarget.getAttribute('data-badgeid')
        handleSelectBadge(badgeId)
      }
    },
    [handleSelectBadge]
  )

  const handleSave = useCallback(() => {
    onSave(currSelectedId)
  }, [currSelectedId, onSave])

  const renderBadge = (badge: PathwayBadgeType) => {
    return (
      <View
        as="div"
        key={badge.id}
        data-badgeid={badge.id}
        display="inline-block"
        shadow="resting"
        padding="medium"
        width="227px"
        height="214px"
        textAlign="center"
        role="button"
        cursor="pointer"
        borderWidth={currSelectedId === badge.id ? 'medium' : 'none'}
        borderColor={currSelectedId === badge.id ? 'primary' : undefined}
        tabIndex={0}
        onClick={handleBadgeClick}
        onKeyDown={handleBadgeKey}
      >
        <div style={{background: 'grey', width: '62px', height: '62px', margin: '0 auto'}} />
        <View as="div" margin="medium 0 0 0">
          <Text as="div" size="medium" weight="bold">
            {badge.title}
          </Text>
        </View>
        <View as="div">
          <Text color="secondary">{badge.issuer.name}</Text>
        </View>
      </View>
    )
  }

  return (
    <Modal
      open={open}
      onDismiss={onClose}
      label="Add Award"
      size="large"
      shouldCloseOnDocumentClick={false}
    >
      <Modal.Header>
        <CloseButton placement="end" offset="medium" onClick={onClose} screenReaderLabel="Close" />
        <Heading>Add Award</Heading>
      </Modal.Header>
      <Modal.Body padding="medium">
        <Flex as="div" gap="small">
          {allBadges.map((badge: PathwayBadgeType) => {
            return renderBadge(badge)
          })}
        </Flex>
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={onClose}>Cancel</Button>
        <Button onClick={handleSave} color="primary" margin="0 0 0 x-small">
          Save
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export default AddBadgeModal
