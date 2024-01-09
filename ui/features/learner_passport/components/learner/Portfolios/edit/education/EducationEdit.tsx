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

import type {EducationData} from '../../../../types'
import EducationModal from './EducationModal'
import EducationCard from '../../../Education/EducationCard'
import {compareFromToDates} from '../../../../shared/utils'

type EducationEditCardProps = {
  education: EducationData
  onRemove: (educationId: string) => void
  onEdit: (education: EducationData) => void
}

const EducationEditCard = ({education, onEdit, onRemove}: EducationEditCardProps) => {
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
        <Flex.Item shouldShrink={false} shouldGrow={true}>
          <View as="div" position="relative">
            <EducationCard education={education} />
            <div
              style={{
                position: 'absolute',
                top: '.5rem',
                right: '.5rem',
              }}
            >
              <IconButton
                screenReaderLabel={`edit education ${education.title}`}
                renderIcon={IconEditLine}
                size="small"
                onClick={() => onEdit(education)}
              />
              <IconButton
                screenReaderLabel={`remove achievement ${education.title}`}
                renderIcon={IconTrashLine}
                margin="0 0 0 x-small"
                size="small"
                onClick={() => onRemove(education.id)}
              />
            </div>
          </View>
        </Flex.Item>
      </Flex>
    </View>
  )
}

type EducationEditProps = {
  education: EducationData[]
  onChange: (education: EducationData[]) => void
}

const EducationEdit = ({education, onChange}: EducationEditProps) => {
  const [expanded, setExpanded] = useState(true)
  const [educationModalOpen, setEducationModalOpen] = useState(false)
  const [editingEducation, setEditingEducation] = useState<EducationData | null>(null)
  const [newEducation, setNewEducation] = useState(education)

  const handleToggle = useCallback((_event: React.MouseEvent, toggleExpanded: boolean) => {
    setExpanded(toggleExpanded)
  }, [])

  const handleAddEducationClick = useCallback(() => {
    setEditingEducation(null)
    setEducationModalOpen(true)
  }, [])

  const handleEducationModalClose = useCallback(() => {
    setEducationModalOpen(false)
  }, [])

  const handleSaveEducation = useCallback(
    changedEducation => {
      setEducationModalOpen(false)
      const index = newEducation.findIndex(edu => edu.id === changedEducation.id)
      if (index === -1) {
        const newEducationList = [...newEducation, changedEducation]
        setNewEducation(newEducationList)
        onChange(newEducationList)
      } else {
        const newEducationList = [...newEducation]
        newEducationList[index] = changedEducation
        setNewEducation(newEducationList)
        onChange(newEducationList)
      }
    },
    [newEducation, onChange]
  )

  const handleEditEducation = useCallback(
    changingEdu => {
      setEditingEducation(changingEdu)
      setEducationModalOpen(true)
    },
    [setEditingEducation, setEducationModalOpen]
  )

  const handleRemoveEducation = useCallback(
    educationId => {
      const newEducationList = newEducation.filter(edu => edu.id !== educationId)
      setNewEducation(newEducationList)
      onChange(newEducationList)
    },
    [newEducation, onChange]
  )

  return (
    <ToggleDetails
      summary={
        <View as="div" margin="small 0">
          <Heading level="h2" themeOverride={{h2FontSize: '1.375rem'}}>
            Education
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
            <Text size="small">Add relevant education experience</Text>
          </View>
          <View as="div" margin="0 0 medium 0">
            <Button renderIcon={IconAddLine} onClick={handleAddEducationClick}>
              Add education
            </Button>
          </View>
          <View as="div" margin="0 0 medium 0">
            {newEducation.sort(compareFromToDates).map(edu => (
              <View key={edu.id} as="div" margin="0 0 medium 0">
                <EducationEditCard
                  education={edu}
                  onEdit={handleEditEducation}
                  onRemove={handleRemoveEducation}
                />
              </View>
            ))}
          </View>
        </View>
        <EducationModal
          open={educationModalOpen}
          education={editingEducation}
          onDismiss={handleEducationModalClose}
          onSave={handleSaveEducation}
        />
      </>
    </ToggleDetails>
  )
}

export default EducationEdit
