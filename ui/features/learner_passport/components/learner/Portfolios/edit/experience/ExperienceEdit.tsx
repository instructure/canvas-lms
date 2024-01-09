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
import {IconAddLine, IconDragHandleLine, IconEditLine, IconTrashLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {View} from '@instructure/ui-view'

import type {ExperienceData} from '../../../../types'
import ExperienceCard from '../../../Experience/ExperienceCard'
import ExperienceModal from './ExperienceModal'
import {compareFromToDates} from '../../../../shared/utils'

type ExperienceEditCardProps = {
  experience: ExperienceData
  onRemove: (experienceId: string) => void
  onEdit: (experience: ExperienceData) => void
}

const ExperienceEditCard = ({experience, onEdit, onRemove}: ExperienceEditCardProps) => {
  return (
    <View as="div" borderWidth="small" shadow="resting">
      <Flex as="div" alignItems="stretch">
        <Flex.Item shouldShrink={false} shouldGrow={false} size="26px">
          <View as="div" position="relative" height="100%" background="secondary">
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
        <Flex.Item shouldShrink={false} shouldGrow={true} size="0">
          <View as="div" position="relative">
            <ExperienceCard experience={experience} />
            <div
              style={{
                position: 'absolute',
                top: '.5rem',
                right: '.5rem',
              }}
            >
              <IconButton
                screenReaderLabel={`edit experience ${experience.title}`}
                renderIcon={IconEditLine}
                size="small"
                onClick={() => onEdit(experience)}
              />
              <IconButton
                screenReaderLabel={`remove achievement ${experience.title}`}
                renderIcon={IconTrashLine}
                margin="0 0 0 x-small"
                size="small"
                onClick={() => onRemove(experience.id)}
              />
            </div>
          </View>
        </Flex.Item>
      </Flex>
    </View>
  )
}

type ExperienceEditProps = {
  experience: ExperienceData[]
  onChange: (experience: ExperienceData[]) => void
}

const ExperienceEdit = ({experience, onChange}: ExperienceEditProps) => {
  const [expanded, setExpanded] = useState(true)

  const [editingExperience, setEditingExperience] = useState<ExperienceData | null>(null)
  const [experienceModalOpen, setExperienceModalOpen] = useState(false)
  const [newExperience, setNewExperience] = useState(experience)

  const handleToggle = useCallback((_event: React.MouseEvent, toggleExpanded: boolean) => {
    setExpanded(toggleExpanded)
  }, [])

  const handleEditExperience = useCallback(
    changingExp => {
      setEditingExperience(changingExp)
      setExperienceModalOpen(true)
    },
    [setEditingExperience, setExperienceModalOpen]
  )

  const handleRemoveExperience = useCallback(
    experienceId => {
      const newExperienceList = newExperience.filter(exp => exp.id !== experienceId)
      setNewExperience(newExperienceList)
      onChange(newExperienceList)
    },
    [newExperience, onChange]
  )

  const handleDismissExperienceModal = useCallback(() => {
    setExperienceModalOpen(false)
    setEditingExperience(null)
  }, [])

  const handleSaveExperience = useCallback(
    changedExperience => {
      handleDismissExperienceModal()
      const index = newExperience.findIndex(exp => exp.id === changedExperience.id)
      if (index === -1) {
        const newExperienceList = [...newExperience, changedExperience]
        setNewExperience(newExperienceList)
        onChange(newExperienceList)
      } else {
        const newExperienceList = [...newExperience]
        newExperienceList[index] = changedExperience
        setNewExperience(newExperienceList)
        onChange(newExperienceList)
      }
    },
    [handleDismissExperienceModal, newExperience, onChange]
  )

  const handleAddExperience = useCallback(() => {
    setExperienceModalOpen(true)
    setEditingExperience(null)
  }, [])

  return (
    <ToggleDetails
      summary={
        <View as="div" margin="small 0">
          <Heading level="h2" themeOverride={{h2FontSize: '1.375rem'}}>
            Experience
          </Heading>
        </View>
      }
      variant="filled"
      expanded={expanded}
      onToggle={handleToggle}
    >
      <>
        <View as="div" margin="medium medium medium 0">
          <View as="div" margin="0 0 x-small 0">
            <Text size="small">Add relevant work experience</Text>
          </View>
          <View as="div" margin="0 0 medium 0">
            <Button renderIcon={IconAddLine} onClick={handleAddExperience}>
              Add experience
            </Button>
          </View>
          <View as="div" margin="0 0 medium 0">
            {newExperience.sort(compareFromToDates).map(exp => (
              <View key={exp.id} as="div" margin="0 0 medium 0">
                <ExperienceEditCard
                  experience={exp}
                  onEdit={handleEditExperience}
                  onRemove={handleRemoveExperience}
                />
              </View>
            ))}
          </View>
        </View>
      </>
      <ExperienceModal
        experience={editingExperience}
        open={experienceModalOpen}
        onDismiss={handleDismissExperienceModal}
        onSave={handleSaveExperience}
      />
    </ToggleDetails>
  )
}

export default ExperienceEdit
