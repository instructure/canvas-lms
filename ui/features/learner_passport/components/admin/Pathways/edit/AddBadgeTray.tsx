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

import React, {useCallback, useContext, useEffect, useState} from 'react'
import {IconArrowOpenStartLine, IconTrashLine} from '@instructure/ui-icons'
import {Button, CloseButton, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Tag} from '@instructure/ui-tag'
import {Text} from '@instructure/ui-text'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import {DataContext} from '../PathwayEditDataContext'
import {isPathwayBadgeType, type PathwayBadgeType} from '../../../types'

type AddBadgeTrayProps = {
  open: boolean
  selectedBadgeId: string | null
  onClose: () => void
  onSave: (badgeId: string | null) => void
}

const AddBadgeTray = ({open, selectedBadgeId, onClose, onSave}: AddBadgeTrayProps) => {
  const {allBadges} = useContext(DataContext)
  const [currSelectedId, setCurrSelectedId] = useState<string | null>(null)

  useEffect(() => {
    setCurrSelectedId(selectedBadgeId)
  }, [selectedBadgeId])

  const handleClose = useCallback(() => {
    setCurrSelectedId(selectedBadgeId)
    onClose()
  }, [onClose, selectedBadgeId])

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

  const renderBadgeForTray = (badge: PathwayBadgeType) => {
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
        {badge.image ? (
          <img
            src={badge.image}
            alt=""
            style={{height: '62px', margin: '0 auto', display: 'block'}}
          />
        ) : (
          <div style={{background: 'grey', width: '62px', height: '62px', margin: '0 auto'}} />
        )}
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
      onDismiss={handleClose}
      size="regular"
      placement="end"
      themeOverride={{regularWidth: '480px'}}
    >
      <Flex as="div" direction="column" height="100vh">
        <Flex as="div" padding="small small 0 medium" direction="row-reverse">
          <Flex.Item>
            <CloseButton
              placement="end"
              offset="small"
              screenReaderLabel="Close"
              onClick={handleClose}
            />
          </Flex.Item>

          <Flex.Item shouldGrow={true} shouldShrink={true}>
            <Heading level="h2">Achievements</Heading>
          </Flex.Item>

          <IconButton
            margin="0 small 0 0"
            screenReaderLabel="back"
            size="small"
            withBackground={false}
            withBorder={false}
            onClick={handleClose}
          >
            <IconArrowOpenStartLine />
          </IconButton>
        </Flex>
        <Flex.Item shouldGrow={true} padding="medium">
          <Text>Select a badge or certificate</Text>
          <Flex as="div" wrap="wrap" gap="small" margin="xx-small 0 0 0">
            {allBadges.map((badge: PathwayBadgeType) => {
              return renderBadgeForTray(badge)
            })}
          </Flex>
        </Flex.Item>
        <Flex.Item align="end" width="100%">
          <View as="div" padding="small medium" borderWidth="small 0 0 0" textAlign="end">
            <Button onClick={handleClose}>Back</Button>
            <Button margin="0 0 0 small" onClick={handleSave}>
              Save Achievement
            </Button>
          </View>
        </Flex.Item>
      </Flex>
    </Tray>
  )
}

const renderBadge = (badge: PathwayBadgeType, onRemove?: () => void) => {
  return (
    <View
      as="div"
      background="secondary"
      borderWidth="small"
      borderRadius="medium"
      margin="small 0"
    >
      <Flex as="div" gap="small" padding="small">
        {badge.image && (
          <Flex.Item shouldShrink={false} shouldGrow={false} width="40px">
            <img src={badge.image} alt="" style={{width: '430px'}} />
          </Flex.Item>
        )}
        <Flex.Item shouldGrow={true}>
          <Text as="div" weight="bold">
            {badge.title}
          </Text>
          <Text as="div">{badge.issuer.name}</Text>
        </Flex.Item>
        {onRemove && (
          <Flex.Item>
            <IconButton
              screenReaderLabel="remove"
              size="small"
              withBackground={false}
              onClick={onRemove}
            >
              <IconTrashLine />
            </IconButton>
          </Flex.Item>
        )}
      </Flex>
      {badge.skills.length > 0 ? (
        <View as="div" padding="small" borderWidth="small 0 0 0">
          <ToggleDetails summary="Skills received">
            <Flex as="div" gap="xx-small" wrap="wrap" margin="small 0 0 0">
              {badge.skills.map(skill => {
                return <Tag key={skill} text={skill} />
              })}
            </Flex>
          </ToggleDetails>
        </View>
      ) : null}
    </View>
  )
}

const renderBadges = (
  allBadges: PathwayBadgeType[],
  badgeId: string | null,
  onRemove?: () => void
) => {
  if (badgeId === null) return null

  const badge = allBadges.find(b => b.id === badgeId)
  return badge ? renderBadge(badge, onRemove) : null
}

const renderCompletionAward = (
  allBadges: PathwayBadgeType[],
  badgeOrId: string | PathwayBadgeType | null
): JSX.Element | undefined => {
  if (!badgeOrId) return undefined
  let badge
  if (typeof badgeOrId === 'string') {
    badge = allBadges.find(b => b.id === badgeOrId)
  }
  if (isPathwayBadgeType(badgeOrId)) {
    badge = badgeOrId
  }
  return badge && renderBadge(badge)
}

export default AddBadgeTray
export {renderBadges, renderBadge, renderCompletionAward}
