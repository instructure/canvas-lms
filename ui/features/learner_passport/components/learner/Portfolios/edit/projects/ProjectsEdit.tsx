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
// import {useSubmit} from 'react-router-dom'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {Heading} from '@instructure/ui-heading'
import {IconAddLine, IconDragHandleLine, IconTrashLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import type {ProjectData} from '../../../../types'
import AddProjectsModal from './AddProjectsModal'
import ProjectCard, {PROJECT_CARD_IMAGE_HEIGHT} from '../../../Projects/ProjectCard'
// import NamingModal from '../../../shared/NamingModal'

interface ProjectEditCardProps {
  project: ProjectData
  onRemove: (projectId: string) => void
}

const ProjectEditCard = ({project, onRemove}: ProjectEditCardProps) => {
  const handleRemoveProject = useCallback(() => {
    onRemove(project.id)
  }, [project.id, onRemove])

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
            <ProjectCard project={project} />
            <div
              style={{
                position: 'absolute',
                top: `calc(${PROJECT_CARD_IMAGE_HEIGHT} + .5rem)`,
                right: '.5rem',
              }}
            >
              <IconButton
                screenReaderLabel={`remove project ${project.title}`}
                renderIcon={IconTrashLine}
                size="small"
                onClick={handleRemoveProject}
              />
            </div>
          </View>
        </Flex.Item>
      </Flex>
    </View>
  )
}

type ProjectsEditProps = {
  allProjects: ProjectData[]
  selectedProjectIds: string[]
  onChange(projecIds: string[]): void
}

const ProjectsEdit = ({allProjects, selectedProjectIds, onChange}: ProjectsEditProps) => {
  // const submit = useSubmit()
  const [addProjectsModalOpen, setAddProjectsModalOpen] = useState(false)
  const [newSelectedProjectIds, setNewSelectedProjectIds] = useState(selectedProjectIds)
  // const [createModalIsOpen, setCreateModalIsOpen] = useState(false)

  const handleAddProjectClick = useCallback(() => {
    setAddProjectsModalOpen(true)
  }, [])

  const handleDismissAddProjedttModal = useCallback(() => {
    setAddProjectsModalOpen(false)
  }, [])

  const handleAddProjectsClick = useCallback(
    (selectedIds: string[]) => {
      setAddProjectsModalOpen(false)
      const newIds = [...newSelectedProjectIds, ...selectedIds]
      setNewSelectedProjectIds(newIds)
      onChange(newIds)
    },
    [onChange, newSelectedProjectIds]
  )

  // const handleCreateNewProject = useCallback(
  //   (f: HTMLFormElement) => {
  //     setCreateModalIsOpen(false)
  //     submit(f, {method: 'PUT'}) <-- this isn't correct yet
  //   },
  //   [submit]
  // )

  // const handleDismissCreateModal = useCallback(() => {
  //   setCreateModalIsOpen(false)
  // }, [])

  // const handleCreateProject = useCallback(() => {
  //   setCreateModalIsOpen(true)
  // }, [])

  const handleRemoveProject = useCallback(
    (projectId: string) => {
      const newIds = newSelectedProjectIds.filter(id => id !== projectId)
      setNewSelectedProjectIds(newIds)
      onChange(newIds)
    },
    [onChange, newSelectedProjectIds]
  )

  const renderProjects = () => {
    return allProjects
      .filter(project => newSelectedProjectIds.includes(project.id))
      .map(project => {
        return <ProjectEditCard project={project} onRemove={handleRemoveProject} />
      })
  }

  return (
    <>
      <View as="div" margin="medium 0 large 0">
        <View as="div">
          <Text size="small">Add or create a project to showcase your skills and achievement</Text>
        </View>
        <View as="div" margin="medium 0 0 0">
          <Button renderIcon={IconAddLine} onClick={handleAddProjectClick}>
            Add project
          </Button>
          {/*
          <Button margin="0 0 0 small" onClick={handleCreateProject}>
            Create new project
          </Button>
        */}
        </View>
        <Flex as="div" margin="medium 0 0 0" gap="medium" wrap="wrap">
          {newSelectedProjectIds.length > 0 ? renderProjects() : null}
        </Flex>
      </View>
      <AddProjectsModal
        projects={allProjects.filter(project => !newSelectedProjectIds.includes(project.id))}
        open={addProjectsModalOpen}
        onDismiss={handleDismissAddProjedttModal}
        onSave={handleAddProjectsClick}
      />
      {/*
      <NamingModal
        objectType="Project"
        objectId=""
        mode="create"
        open={createModalIsOpen}
        onDismiss={handleDismissCreateModal}
        onSubmit={handleCreateNewProject}
      />
      */}
    </>
  )
}

const ProjectsEditToggle = (props: ProjectsEditProps) => {
  const [expanded, setExpanded] = useState(true)

  const handleToggle = useCallback((_event: React.MouseEvent, toggleExpanded: boolean) => {
    setExpanded(toggleExpanded)
  }, [])

  return (
    <ToggleDetails
      summary={
        <View as="div" margin="small 0">
          <Heading level="h2" themeOverride={{h2FontSize: '1.375rem'}}>
            Projects
          </Heading>
        </View>
      }
      variant="filled"
      expanded={expanded}
      onToggle={handleToggle}
    >
      <ProjectsEdit {...props} />
    </ToggleDetails>
  )
}

export default ProjectsEditToggle
export {ProjectsEdit}
