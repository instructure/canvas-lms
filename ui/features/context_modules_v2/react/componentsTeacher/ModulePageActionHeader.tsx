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

import React, {useCallback} from 'react'
import {queryClient} from '@canvas/query'
import {handleOpeningModuleUpdateTray} from '../handlers/modulePageActionHandlers'
import ContextModulesHeader from '@canvas/context-modules/react/ContextModulesHeader'
import {useContextModule} from '../hooks/useModuleContext'
import {useModules} from '../hooks/queries/useModules'
import {MODULE_ITEMS, MODULES} from '../utils/constants'
import {ModulesPageIconLegend} from './ModulesPageIconLegend'

interface ModulePageActionHeaderProps {
  onCollapseAll: () => void
  onExpandAll: () => void
  anyModuleExpanded?: boolean
  disabled?: boolean
}

const ModulePageActionHeader: React.FC<ModulePageActionHeaderProps> = ({
  onCollapseAll,
  onExpandAll,
  anyModuleExpanded = true,
  disabled = false,
}) => {
  const {courseId} = useContextModule()
  const {data} = useModules(courseId)

  const handleCollapseExpandClick = useCallback(() => {
    if (anyModuleExpanded) {
      onCollapseAll()
    } else {
      onExpandAll()
    }
  }, [anyModuleExpanded, onCollapseAll, onExpandAll])

  const handlePublishComplete = useCallback(() => {
    queryClient.invalidateQueries({queryKey: [MODULES, courseId]})
    // invalidate all queries that start with 'moduleItems' in their query key
    queryClient.invalidateQueries({queryKey: [MODULE_ITEMS]})
    queryClient.invalidateQueries({queryKey: ['MODULE_ITEMS_ALL']})
  }, [courseId])

  const handleAddModule = useCallback(() => {
    handleOpeningModuleUpdateTray(data, courseId, undefined)
  }, [data, courseId])

  return (
    <ContextModulesHeader
      {...ENV.CONTEXT_MODULES_HEADER_PROPS}
      overrides={{
        publishMenu: {
          onPublishComplete: handlePublishComplete,
        },
        expandCollapseAll: {
          onExpandCollapseAll: handleCollapseExpandClick,
          anyModuleExpanded,
          disabled,
        },
        handleAddModule: handleAddModule,
        renderIconLegend: () => (
          <ModulesPageIconLegend is_blueprint_course={!!ENV.MASTER_COURSE_SETTINGS} />
        ),
      }}
    />
  )
}

export default ModulePageActionHeader
