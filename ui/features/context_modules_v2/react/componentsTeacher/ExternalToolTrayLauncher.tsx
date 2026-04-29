/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import React, {Suspense, lazy} from 'react'
import {ExternalTool} from '../utils/types'
import {useContextModule} from '../hooks/useModuleContext'
import {useModuleItems} from '../hooks/queries/useModuleItems'

const ContentTypeExternalToolTray = lazy(
  () => import('@canvas/trays/react/ContentTypeExternalToolTray'),
)

interface ExternalToolTrayLauncherProps {
  tool: ExternalTool
  isOpen: boolean
  onClose: () => void
  contextModuleId: string
  launchType: string
  moduleId: string
  expanded: boolean
  isMenuOpen: boolean
}

const ExternalToolTrayLauncher: React.FC<ExternalToolTrayLauncherProps> = ({
  tool,
  isOpen,
  onClose,
  contextModuleId,
  launchType,
  moduleId,
  expanded,
  isMenuOpen,
}) => {
  const {courseId} = useContextModule()
  const {data: moduleItems} = useModuleItems(moduleId, null, expanded || isMenuOpen)

  const handleExternalContentReady = () => {
    onClose()
    window.location.reload()
  }

  // Transform tool data to match ContentTypeExternalToolTray expectations
  const trayTool = {
    id: 'id' in tool ? tool.id : tool.definition_id.toString(),
    title: 'title' in tool ? tool.title : tool.name,
    base_url:
      'base_url' in tool
        ? tool.base_url
        : `/courses/${courseId}/external_tools/${tool.definition_id}`,
    icon_url: 'icon_url' in tool ? tool.icon_url || '' : '',
  }

  const extraQueryParams = contextModuleId ? {context_module_id: contextModuleId} : {}

  return (
    <Suspense fallback={<div>Loading...</div>}>
      <ContentTypeExternalToolTray
        tool={trayTool}
        placement={launchType}
        acceptedResourceTypes={['module']}
        targetResourceType="module"
        allowItemSelection={false}
        selectableItems={
          moduleItems?.moduleItems?.map(() => ({
            course_id: courseId,
            type: 'module' as const,
          })) || []
        }
        onDismiss={onClose}
        onExternalContentReady={handleExternalContentReady}
        open={isOpen}
        extraQueryParams={extraQueryParams}
      />
    </Suspense>
  )
}

export default ExternalToolTrayLauncher
