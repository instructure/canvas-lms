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
import {Button} from '@instructure/ui-buttons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {queryClient} from '@canvas/query'
import {handleOpeningModuleUpdateTray} from '../handlers/modulePageActionHandlers'
import ContextModulesHeader from '@canvas/context-modules/react/ContextModulesHeader'
import {useContextModule} from '../hooks/useModuleContext'
import {useModules} from '../hooks/queries/useModules'

const I18n = createI18nScope('context_modules_v2')

interface ModulePageActionHeaderProps {
  onCollapseAll: () => void
  onExpandAll: () => void
  anyModuleExpanded?: boolean
}

const ModulePageActionHeader: React.FC<ModulePageActionHeaderProps> = ({
  onCollapseAll,
  onExpandAll,
  anyModuleExpanded = true,
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
    queryClient.invalidateQueries({queryKey: ['modules', courseId]})
    // invalidate all queries that start with 'moduleItems' in their query key
    queryClient.invalidateQueries({queryKey: ['moduleItems']})
  }, [courseId])

  const handleAddModule = useCallback(() => {
    handleOpeningModuleUpdateTray(data, courseId, undefined)
  }, [data, courseId])

  const renderExpandCollapseAll = useCallback(
    (displayOptions?: {
      display: 'block' | 'inline-block' | undefined
      ariaExpanded: boolean
      dataExpand: boolean
      ariaLabel: string
    }) => {
      return (
        <Button
          onClick={handleCollapseExpandClick}
          display={displayOptions?.display}
          aria-expanded={displayOptions?.ariaExpanded}
          data-expand={displayOptions?.dataExpand}
          aria-label={displayOptions?.ariaLabel}
        >
          {anyModuleExpanded ? I18n.t('Collapse All') : I18n.t('Expand All')}
        </Button>
      )
    },
    [anyModuleExpanded, handleCollapseExpandClick],
  )

  return (
    <ContextModulesHeader
      // @ts-expect-error
      {...ENV.CONTEXT_MODULES_HEADER_PROPS}
      overrides={{
        expandCollapseAll: {renderComponent: renderExpandCollapseAll},
        publishMenu: {
          onPublishComplete: handlePublishComplete,
        },
        handleAddModule: handleAddModule,
      }}
    />
  )
}

export default ModulePageActionHeader
