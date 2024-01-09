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
import {IconButton} from '@instructure/ui-buttons'
import {
  IconCopyLine,
  IconDownloadLine,
  IconEditLine,
  IconLinkLine,
  IconMoreLine,
  IconResetLine,
  IconReviewScreenLine,
  IconTrashLine,
} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import type {MenuItemProps} from '@instructure/ui-menu'
import {View} from '@instructure/ui-view'
import type {ViewOwnProps} from '@instructure/ui-view'
import ProjectCard, {
  PROJECT_CARD_WIDTH,
  PROJECT_CARD_HEIGHT,
  PROJECT_CARD_IMAGE_HEIGHT,
} from './ProjectCard'
import type {ProjectData} from '../../types'

export type ProjectDashboardCardProps = {
  project: ProjectData
  onAction: (projectId: string, action: string) => void
}

const ProjectDashboardCard = ({project, onAction}: ProjectDashboardCardProps) => {
  const [kabobButtonRef, setKabobButtonRef] = useState<Element | null>(null)

  const handleKabobMenuSelect = useCallback(
    (
      e: React.MouseEvent<Element, MouseEvent>,
      value: MenuItemProps['value'] | MenuItemProps['value'][]
    ) => {
      e.preventDefault()
      e.stopPropagation()
      if (!value) return
      if (typeof value !== 'string') return
      onAction(project.id, value)
    },
    [onAction, project.id]
  )

  const handleCardClick = useCallback(
    (e: React.MouseEvent<ViewOwnProps, MouseEvent>) => {
      if (e.target === kabobButtonRef) return
      onAction(project.id, 'view')
    },
    [kabobButtonRef, onAction, project.id]
  )

  return (
    <View
      id={`project-${project.id}`}
      as="div"
      background="primary"
      width={PROJECT_CARD_WIDTH}
      height={PROJECT_CARD_HEIGHT}
      role="button"
      cursor="pointer"
      onClick={handleCardClick}
      position="relative"
      shadow="resting"
    >
      <div style={{position: 'absolute', top: PROJECT_CARD_IMAGE_HEIGHT, right: 0}}>
        <Menu
          onSelect={handleKabobMenuSelect}
          placement="bottom"
          trigger={
            <IconButton
              elementRef={(el: Element | null) => setKabobButtonRef(el)}
              screenReaderLabel="More"
              withBackground={false}
              withBorder={false}
            >
              <IconMoreLine />
            </IconButton>
          }
        >
          <Menu.Item value="view">
            <IconReviewScreenLine /> View
          </Menu.Item>
          <Menu.Item value="edit">
            <IconEditLine /> Edit
          </Menu.Item>
          <Menu.Item value="duplicate">
            <IconCopyLine /> Duplicate
          </Menu.Item>
          <Menu.Item value="download">
            <IconDownloadLine /> Download
          </Menu.Item>
          <Menu.Item value="rename">
            <IconEditLine /> Rename
          </Menu.Item>
          <Menu.Item value="share">
            <IconLinkLine /> Copy share link
          </Menu.Item>
          <Menu.Item value="regen_share">
            <IconResetLine /> Regenerate share link
          </Menu.Item>
          <Menu.Item value="delete">
            <IconTrashLine /> Delete
          </Menu.Item>
        </Menu>
      </div>
      <ProjectCard project={project} />
    </View>
  )
}

export default ProjectDashboardCard
export {PROJECT_CARD_HEIGHT, PROJECT_CARD_WIDTH}
