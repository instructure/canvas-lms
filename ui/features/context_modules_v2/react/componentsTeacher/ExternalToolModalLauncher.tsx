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

const ExternalToolModalLauncher = lazy(
  () => import('@canvas/external-tools/react/components/ExternalToolModalLauncher'),
)

interface ExternalToolModalLauncherWrapperProps {
  tool: ExternalTool
  isOpen: boolean
  onClose: () => void
  contextModuleId: string | null
  launchType: string
}

const ExternalToolModalLauncherWrapper: React.FC<ExternalToolModalLauncherWrapperProps> = ({
  tool,
  isOpen,
  onClose,
  contextModuleId,
  launchType,
}) => {
  const {courseId} = useContextModule()

  const handleExternalContentReady = () => {
    onClose()
    window.location.reload()
  }

  // Transform tool data to match ExternalToolModalLauncher expectations
  const modalTool = {
    definition_id: 'definition_id' in tool ? tool.definition_id.toString() : tool.id,
    placements:
      'placements' in tool
        ? Object.fromEntries(
            Object.entries(tool.placements).map(([key, value]) => [
              key,
              value
                ? {
                    selection_width: value.selection_width,
                    selection_height: value.selection_height,
                    launch_width: value.launch_width,
                    launch_height: value.launch_height,
                  }
                : {},
            ]),
          )
        : {},
  }

  const title = 'name' in tool ? tool.name : tool.title

  return (
    <Suspense fallback={<div>Loading...</div>}>
      <ExternalToolModalLauncher
        tool={modalTool}
        isOpen={isOpen}
        onRequestClose={onClose}
        contextType="course"
        contextId={courseId}
        launchType={launchType}
        title={title}
        contextModuleId={contextModuleId || undefined}
        onExternalContentReady={handleExternalContentReady}
      />
    </Suspense>
  )
}

export default ExternalToolModalLauncherWrapper
