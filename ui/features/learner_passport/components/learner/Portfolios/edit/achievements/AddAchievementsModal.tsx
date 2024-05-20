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
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import type {AchievementData} from '../../../../types'
import AchievementCard from '../../../Achievements/AchievementCard'

interface AddAchievementCardProps {
  achievement: AchievementData
  selected: boolean
  onChange: (achievementId: string, selected: boolean) => void
}

const AddAchievementCard = ({achievement, selected, onChange}: AddAchievementCardProps) => {
  const handleSelectAchievement = useCallback(
    (event: React.ChangeEvent<HTMLInputElement>) => {
      onChange(achievement.id, event.target.checked)
    },
    [achievement.id, onChange]
  )

  return (
    <View as="div" display="inline-block" position="relative" borderWidth="small" shadow="resting">
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
          right: '0',
        }}
      >
        <Checkbox
          label={<ScreenReaderContent>Select achievement</ScreenReaderContent>}
          value={achievement.id}
          checked={selected}
          onChange={handleSelectAchievement}
        />
      </div>
    </View>
  )
}

interface AddAchievementsModalProps {
  achievements: AchievementData[]
  open: boolean
  onDismiss: () => void
  onSave: (selectedIds: string[]) => void
}

const AddAchievementsModal = ({
  achievements,
  open,
  onDismiss,
  onSave,
}: AddAchievementsModalProps) => {
  const [selectedAchievementIds, setSelectedAchievementIds] = useState<string[]>([])

  const handleDismiss = useCallback(() => {
    onDismiss()
  }, [onDismiss])

  const handleSave = useCallback(() => {
    onSave(selectedAchievementIds)
  }, [onSave, selectedAchievementIds])

  const handleChangeSelection = useCallback(
    (achievementId: string, selected: boolean) => {
      if (selected) {
        setSelectedAchievementIds([...selectedAchievementIds, achievementId])
      } else {
        setSelectedAchievementIds(selectedAchievementIds.filter(id => id !== achievementId))
      }
    },
    [selectedAchievementIds]
  )

  const renderBodyContents = () => {
    if (achievements.length === 0) {
      return (
        <View as="div" padding="small" minWidth="23rem">
          <Text>No achievements available</Text>
        </View>
      )
    }
    return (
      <>
        <View as="div" margin="0 0 medium 0">
          <Text>{selectedAchievementIds.length} achievements selected</Text>
        </View>
        <Flex as="div" padding="small" wrap="wrap" gap="small">
          {achievements.map(achievement => (
            <AddAchievementCard
              key={achievement.id}
              achievement={achievement}
              selected={selectedAchievementIds.includes(achievement.id)}
              onChange={handleChangeSelection}
            />
          ))}
        </Flex>
      </>
    )
  }

  return (
    <Modal open={open} size="auto" label="Edit Cover Image" onDismiss={onDismiss}>
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="medium"
          onClick={handleDismiss}
          screenReaderLabel="Close"
        />
        <Heading>Add Achievements</Heading>
      </Modal.Header>
      <Modal.Body>
        <View as="div" margin="small 0">
          {renderBodyContents()}
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Button color="secondary" onClick={handleDismiss}>
          Cancel
        </Button>
        <Button color="primary" margin="0 0 0 small" onClick={handleSave}>
          Add achievements
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export default AddAchievementsModal
