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
import type {ProjectData} from '../../../../types'
import ProjectCard from '../../../Projects/ProjectCard'

interface AddProjectCardProps {
  project: ProjectData
  selected: boolean
  onChange: (projectId: string, selected: boolean) => void
}

const AddProjectCard = ({project, selected, onChange}: AddProjectCardProps) => {
  const handleSelectProject = useCallback(
    (event: React.ChangeEvent<HTMLInputElement>) => {
      onChange(project.id, event.target.checked)
    },
    [project.id, onChange]
  )

  return (
    <View as="div" display="inline-block" position="relative" borderWidth="small" shadow="resting">
      <ProjectCard project={project} />
      <div
        style={{
          position: 'absolute',
          top: '0.5rem',
          right: '0',
        }}
      >
        <Checkbox
          label={<ScreenReaderContent>Select project</ScreenReaderContent>}
          value={project.id}
          checked={selected}
          onChange={handleSelectProject}
        />
      </div>
    </View>
  )
}

interface AddProjectsModalProps {
  projects: ProjectData[]
  open: boolean
  onDismiss: () => void
  onSave: (selectedIds: string[]) => void
}

const AddProjectsModal = ({projects, open, onDismiss, onSave}: AddProjectsModalProps) => {
  const [selectedProjectIds, setSelectedProjectIds] = useState<string[]>([])

  const handleDismiss = useCallback(() => {
    onDismiss()
  }, [onDismiss])

  const handleSave = useCallback(() => {
    onSave(selectedProjectIds)
  }, [onSave, selectedProjectIds])

  const handleChangeSelection = useCallback(
    (projectId: string, selected: boolean) => {
      if (selected) {
        setSelectedProjectIds([...selectedProjectIds, projectId])
      } else {
        setSelectedProjectIds(selectedProjectIds.filter(id => id !== projectId))
      }
    },
    [selectedProjectIds]
  )

  const renderBodyContents = () => {
    if (projects.length === 0) {
      return (
        <View as="div" padding="small" minWidth="23rem">
          <Text>No projects available</Text>
        </View>
      )
    }
    return (
      <>
        <View as="div" margin="0 0 medium 0">
          <Text>{selectedProjectIds.length} projects selected</Text>
        </View>
        <Flex as="div" padding="small" wrap="wrap" gap="small">
          {projects.map(project => (
            <AddProjectCard
              key={project.id}
              project={project}
              selected={selectedProjectIds.includes(project.id)}
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
        <Heading>Add Projects</Heading>
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
          Add projects
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export default AddProjectsModal
