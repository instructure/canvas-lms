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

import {useCallback, useState} from 'react'
import {useContextModule} from './useModuleContext'
import {ExternalTool, ExternalToolPlacementType, ExternalToolTrayItem} from '../utils/types'

export interface ExternalToolLaunchState {
  isModalOpen: boolean
  isTrayOpen: boolean
  selectedTool: ExternalTool | null
  contextModuleId: string | null
  launchType: ExternalToolPlacementType | null
}

export const useExternalToolLaunch = () => {
  const {
    courseId,
    moduleGroupMenuTools,
    moduleMenuModalTools,
    moduleMenuTools,
    moduleIndexMenuModalTools,
  } = useContextModule()

  const [launchState, setLaunchState] = useState<ExternalToolLaunchState>({
    isModalOpen: false,
    isTrayOpen: false,
    selectedTool: null,
    contextModuleId: null,
    launchType: null,
  })

  const launchExternalTool = useCallback(
    (tool: ExternalTool, moduleId: string, placement: ExternalToolPlacementType) => {
      if (placement === 'module_menu') {
        // Navigate in current tab for module_menu placement
        const trayTool = tool as ExternalToolTrayItem
        // Use the same URL pattern as legacy: /courses/{course_id}/external_tools/{tool_id}?launch_type=module_menu&modules%5B%5D={module_id}
        const toolId = trayTool.id
        const launchUrl = `/courses/${courseId}/external_tools/${toolId}?launch_type=module_menu&modules%5B%5D=${moduleId}`
        // eslint-disable-next-line react-compiler/react-compiler
        window.location.href = launchUrl
      } else if (placement === 'module_group_menu') {
        // Launch tray for module_group_menu
        setLaunchState({
          isModalOpen: false,
          isTrayOpen: true,
          selectedTool: tool,
          contextModuleId: moduleId,
          launchType: placement,
        })
      } else if (placement === 'module_menu_modal' || placement === 'module_index_menu_modal') {
        // Launch modal for these placements
        setLaunchState({
          isModalOpen: true,
          isTrayOpen: false,
          selectedTool: tool,
          contextModuleId: moduleId,
          launchType: placement,
        })
      }
    },
    [],
  )

  const closeLaunch = useCallback(() => {
    setLaunchState({
      isModalOpen: false,
      isTrayOpen: false,
      selectedTool: null,
      contextModuleId: null,
      launchType: null,
    })
  }, [])

  return {
    launchState,
    launchExternalTool,
    closeLaunch,
    moduleGroupMenuTools,
    moduleMenuModalTools,
    moduleMenuTools,
    moduleIndexMenuModalTools,
    courseId,
  }
}
