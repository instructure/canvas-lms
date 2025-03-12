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

import React, { useState, useCallback } from 'react'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {IconButton} from '@instructure/ui-buttons'
import {IconPlusLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import ContextModulesPublishIcon from '@canvas/context-modules/react/ContextModulesPublishIcon'
import DirectShareUserModal from '@canvas/direct-sharing/react/components/DirectShareUserModal'
import DirectShareCourseTray from '@canvas/direct-sharing/react/components/DirectShareCourseTray'
import { queryClient } from '@canvas/query'
import ModuleActionMenu from '../componentsTeacher/ModuleActionMenu'
import {
  handlePublishComplete,
} from '../handlers/moduleActionHandlers'
import { Pill } from '@instructure/ui-pill'
import {Prerequisite, CompletionRequirement} from '../utils/types'
import {useContextModule} from '../hooks/useModuleContext'

const I18n = createI18nScope('context_modules_v2')

interface ModuleHeaderActionPanelProps {
  id: string
  name: string
  published?: boolean
  prerequisites?: Prerequisite[]
  completionRequirements?: CompletionRequirement[]
  requirementCount?: number
  handleOpeningModuleUpdateTray?: (moduleId?: string, moduleName?: string, prerequisites?: {id: string, name: string, type: string}[], openTab?: 'settings' | 'assign-to') => void
  onAddItem?: (id: string, name: string) => void
}

const ModuleHeaderActionPanel: React.FC<ModuleHeaderActionPanelProps> = ({
  id,
  name,
  published = false,
  prerequisites,
  completionRequirements,
  requirementCount = null,
  handleOpeningModuleUpdateTray,
  onAddItem
}) => {
  const [isMenuOpen, setIsMenuOpen] = useState(false)
  const [isDirectShareOpen, setIsDirectShareOpen] = useState(false)
  const [isDirectShareCourseOpen, setIsDirectShareCourseOpen] = useState(false)
  const {courseId} = useContextModule()

  const onPublishCompleteRef = useCallback(() => {
    handlePublishComplete(queryClient, id, courseId)
  }, [queryClient, id, courseId])

  return (
    <>
    <Flex gap="small" alignItems="center" justifyItems="end" wrap='wrap'>
      {prerequisites?.length && <Flex.Item>
        <Text size="small" color="secondary">
          {I18n.t('Prerequisites: %{prerequisiteModuleName}', { prerequisiteModuleName: prerequisites?.map?.(p => p.name).join(', ') || '' })}
        </Text>
      </Flex.Item>}
      {completionRequirements?.length && <Flex.Item>
        <Pill>
          <Text size="medium" weight='bold'>
            {requirementCount ? I18n.t('Complete One Item') : I18n.t('Complete All Items')}
          </Text>
        </Pill>
      </Flex.Item>}
      <Flex.Item>
        <ContextModulesPublishIcon
          courseId={courseId}
          moduleId={id}
          moduleName={name}
          published={published}
          isPublishing={false}
          onPublishComplete={onPublishCompleteRef}
        />
      </Flex.Item>
      <Flex.Item>
        <IconButton
          size="small"
          screenReaderLabel={I18n.t("Add Item")}
          renderIcon={IconPlusLine}
          withBorder={false}
          withBackground={true}
          onClick={() => onAddItem?.(id, name)}
        />
      </Flex.Item>
      <Flex.Item>
        <ModuleActionMenu
          isMenuOpen={isMenuOpen}
          setIsMenuOpen={setIsMenuOpen}
          id={id}
          name={name}
          prerequisites={prerequisites}
          handleOpeningModuleUpdateTray={handleOpeningModuleUpdateTray}
          setIsDirectShareOpen={setIsDirectShareOpen}
          setIsDirectShareCourseOpen={setIsDirectShareCourseOpen}
        />
      </Flex.Item>
    </Flex>
    <DirectShareUserModal
      open={isDirectShareOpen}
      sourceCourseId={courseId}
      courseId={courseId}
      contentShare={{content_type: 'module', content_id: id}}
      onDismiss={() => {
        setIsDirectShareOpen(false)
      }}
    />
    <DirectShareCourseTray
      open={isDirectShareCourseOpen}
      sourceCourseId={courseId}
      courseId={courseId}
      contentSelection={{modules: [id]}}
      onDismiss={() => {
        setIsDirectShareCourseOpen(false)
      }}
    />
    </>
  )
}

export default ModuleHeaderActionPanel