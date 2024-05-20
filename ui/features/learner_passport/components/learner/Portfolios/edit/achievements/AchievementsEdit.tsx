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

import React, {useCallback, useState} from 'react'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconAddLine, IconDragHandleLine, IconTrashLine} from '@instructure/ui-icons'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {View} from '@instructure/ui-view'

import type {AchievementData} from '../../../../types'
import AchievementCard from '../../../Achievements/AchievementCard'
import AddAchievementsModal from './AddAchievementsModal'

interface AchievementEditCardProps {
  achievement: AchievementData
  onRemove: (achievementId: string) => void
}

const AchievementEditCard = ({achievement, onRemove}: AchievementEditCardProps) => {
  const handleRemoveAchievement = useCallback(() => {
    onRemove(achievement.id)
  }, [achievement.id, onRemove])

  return (
    <View as="div" borderWidth="small" shadow="resting">
      <Flex as="div" alignItems="stretch">
        <Flex.Item shouldShrink={false} shouldGrow={false}>
          <View as="div" position="relative" width="26px" height="100%" background="secondary">
            <div
              style={{
                position: 'absolute',
                top: '50%',
                left: '50%',
                transform: 'translate(-50%, -50%)',
                cursor: 'grab',
              }}
            >
              <IconDragHandleLine inline={false} />
            </div>
          </View>
        </Flex.Item>
        <Flex.Item shouldShrink={false} shouldGrow={false}>
          <View as="div" position="relative" display="inline-block">
            <AchievementCard
              isNew={false}
              title={achievement.title}
              issuer={achievement.issuer.name}
              imageUrl={achievement.imageUrl}
            />
            <div
              style={{
                position: 'absolute',
                top: '0.5rem',
                right: '0.5rem',
              }}
            >
              <IconButton
                screenReaderLabel={`remove achievement ${achievement.title}`}
                renderIcon={IconTrashLine}
                size="small"
                onClick={handleRemoveAchievement}
              />
            </div>
          </View>
        </Flex.Item>
      </Flex>
    </View>
  )
}

type AchievementsEditProps = {
  allAchievements: AchievementData[]
  selectedAchievementIds: string[]
  onChange(achievementIds: string[]): void
}

const AchievementsEdit = ({
  allAchievements,
  selectedAchievementIds,
  onChange,
}: AchievementsEditProps) => {
  const [addAchievementsModalOpen, setAddAchievementsModalOpen] = useState(false)
  const [newSelectedAchievementIds, setNewSelectedAchievementIds] = useState(selectedAchievementIds)

  const handleAddAchievementClick = useCallback(() => {
    setAddAchievementsModalOpen(true)
  }, [])

  const handleDismissAddAchievementModal = useCallback(() => {
    setAddAchievementsModalOpen(false)
  }, [])

  const handleAddAchievementsClick = useCallback(
    (selectedIds: string[]) => {
      setAddAchievementsModalOpen(false)
      const newIds = [...newSelectedAchievementIds, ...selectedIds]
      setNewSelectedAchievementIds(newIds)
      onChange(newIds)
    },
    [onChange, newSelectedAchievementIds]
  )

  const handleRemoveAchievement = useCallback(
    (achievementId: string) => {
      const newIds = newSelectedAchievementIds.filter(id => id !== achievementId)
      setNewSelectedAchievementIds(newIds)
      onChange(newIds)
    },
    [onChange, newSelectedAchievementIds]
  )

  const renderAchievements = () => {
    return allAchievements
      .filter(achievement => newSelectedAchievementIds.includes(achievement.id))
      .map(achievement => {
        return (
          <Flex.Item key={achievement.id} shouldShrink={false}>
            <AchievementEditCard achievement={achievement} onRemove={handleRemoveAchievement} />
          </Flex.Item>
        )
      })
  }

  return (
    <>
      <View as="div" margin="medium 0 large 0">
        <View as="div" margin="medium 0 0 0">
          <Button renderIcon={IconAddLine} onClick={handleAddAchievementClick}>
            Add achievements
          </Button>
        </View>
        <Flex as="div" margin="medium 0 0 0" gap="medium" wrap="wrap">
          {newSelectedAchievementIds.length > 0 ? renderAchievements() : null}
        </Flex>
      </View>
      <AddAchievementsModal
        achievements={allAchievements.filter(
          achievement => !newSelectedAchievementIds.includes(achievement.id)
        )}
        open={addAchievementsModalOpen}
        onDismiss={handleDismissAddAchievementModal}
        onSave={handleAddAchievementsClick}
      />
    </>
  )
}

const AchievementsEditToggle = (props: AchievementsEditProps) => {
  const [expanded, setExpanded] = useState(true)

  const handleToggle = useCallback((_event: React.MouseEvent, toggleExpanded: boolean) => {
    setExpanded(toggleExpanded)
  }, [])

  return (
    <ToggleDetails
      summary={
        <View as="div" margin="small 0">
          <Heading level="h2" themeOverride={{h2FontSize: '1.375rem'}}>
            Achievements
          </Heading>
        </View>
      }
      variant="filled"
      expanded={expanded}
      onToggle={handleToggle}
    >
      <AchievementsEdit {...props} />
    </ToggleDetails>
  )
}

export default AchievementsEditToggle
export {AchievementEditCard, AchievementsEdit}
