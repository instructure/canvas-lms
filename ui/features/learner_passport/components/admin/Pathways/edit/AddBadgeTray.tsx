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
import {Text} from '@instructure/ui-text'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'

import type {PathwayBadgeType} from '../../../types'

type AddBadgeTrayProps = {
  allBadges: PathwayBadgeType[]
  open: boolean
  selectedBadgeId: string | null
  onClose: () => void
  onSave: (badgeId: string | null) => void
}

const AddBadgeTray = ({allBadges, open, selectedBadgeId, onClose, onSave}: AddBadgeTrayProps) => {
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
        width="210px"
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
    <Tray
      label="Achievements"
      open={open}
      onDismiss={onClose}
      size="regular"
      placement="end"
      themeOverride={{regularWidth: '480px'}}
    >
      <Flex as="div" direction="column" height="100vh">
        <Flex as="div" padding="small small 0 medium">
          <Flex.Item shouldGrow={true} shouldShrink={true}>
            <Heading level="h2" margin="0 0 small 0">
              Achievements
            </Heading>
          </Flex.Item>
          <Flex.Item>
            <CloseButton
              placement="end"
              offset="small"
              screenReaderLabel="Close"
              onClick={onClose}
            />
          </Flex.Item>
        </Flex>
        <Flex.Item shouldGrow={true} padding="medium">
          <Text>Select a badge or certificate</Text>
          <Flex as="div" wrap="wrap" gap="small" margin="xx-small 0 0 0">
            {allBadges.map((badge: PathwayBadgeType) => {
              return renderBadge(badge)
            })}
          </Flex>
        </Flex.Item>
        <Flex.Item align="end" width="100%">
          <View as="div" padding="small medium" borderWidth="small 0 0 0" textAlign="end">
            <Button onClick={onClose}>Cancel</Button>
            <Button margin="0 0 0 small" onClick={handleSave}>
              Save Achievement
            </Button>
          </View>
        </Flex.Item>
      </Flex>
    </Tray>
  )
}

export default AddBadgeTray
