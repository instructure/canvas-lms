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

import React, {useState, useCallback} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {IconButton} from '@instructure/ui-buttons'
import {IconPlusLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import ContextModulesPublishIcon from '@canvas/context-modules/react/ContextModulesPublishIcon'
import DirectShareUserModal from '@canvas/direct-sharing/react/components/DirectShareUserModal'
import DirectShareCourseTray from '@canvas/direct-sharing/react/components/DirectShareCourseTray'
import {queryClient} from '@canvas/query'
import ModuleActionMenu from '../componentsTeacher/ModuleActionMenu'
import {handlePublishComplete} from '../handlers/moduleActionHandlers'
import {Pill} from '@instructure/ui-pill'
import {Prerequisite, CompletionRequirement, ModuleAction} from '../utils/types'
import {useContextModule} from '../hooks/useModuleContext'
import AddItemModal from './AddItemModalComponents/AddItemModal'
import ViewAssignTo from './ViewAssignToTrayComponents/ViewAssignTo'

const I18n = createI18nScope('context_modules_v2')

interface ModuleHeaderActionPanelProps {
  id: string
  name: string
  expanded?: boolean
  published?: boolean
  prerequisites?: Prerequisite[]
  completionRequirements?: CompletionRequirement[]
  requirementCount?: number
  itemCount?: number
  hasActiveOverrides: boolean
  setModuleAction?: React.Dispatch<React.SetStateAction<ModuleAction | null>>
  setIsManageModuleContentTrayOpen?: React.Dispatch<React.SetStateAction<boolean>>
  setSourceModule?: React.Dispatch<React.SetStateAction<{id: string; title: string} | null>>
}

const ModuleHeaderActionPanel: React.FC<ModuleHeaderActionPanelProps> = ({
  id,
  name,
  expanded = false,
  published = false,
  prerequisites,
  completionRequirements,
  requirementCount = null,
  itemCount,
  hasActiveOverrides,
  setModuleAction,
  setIsManageModuleContentTrayOpen,
  setSourceModule,
}) => {
  const [isMenuOpen, setIsMenuOpen] = useState(false)
  const [isDirectShareOpen, setIsDirectShareOpen] = useState(false)
  const [isDirectShareCourseOpen, setIsDirectShareCourseOpen] = useState(false)
  const [isAddItemOpen, setIsAddItemOpen] = useState(false)
  const {courseId} = useContextModule()

  const onPublishCompleteRef = useCallback(() => {
    handlePublishComplete(queryClient, id, courseId)
  }, [id, courseId])

  return (
    <>
      <Flex gap="small" alignItems="center" justifyItems="end" wrap="wrap">
        {prerequisites?.length && (
          <Flex.Item>
            <Text size="small" color="secondary">
              {I18n.t(
                {
                  one: 'Prerequisite: %{prerequisiteModuleName}',
                  other: 'Prerequisites: %{prerequisiteModuleName}',
                },
                {
                  count: prerequisites?.length || 0,
                  prerequisiteModuleName: prerequisites?.map?.(p => p.name).join(', ') || '',
                },
              )}
            </Text>
          </Flex.Item>
        )}
        {completionRequirements?.length && (
          <Flex.Item>
            <Pill>
              <Text size="medium" weight="bold">
                {requirementCount ? I18n.t('Complete One Item') : I18n.t('Complete All Items')}
              </Text>
            </Pill>
          </Flex.Item>
        )}
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
            screenReaderLabel={I18n.t('Add Item')}
            renderIcon={IconPlusLine}
            withBorder={false}
            withBackground={true}
            onClick={() => setIsAddItemOpen(true)}
          />
        </Flex.Item>
        <Flex.Item>
          <ModuleActionMenu
            expanded={expanded}
            isMenuOpen={isMenuOpen}
            setIsMenuOpen={setIsMenuOpen}
            id={id}
            name={name}
            prerequisites={prerequisites}
            setIsDirectShareOpen={setIsDirectShareOpen}
            setIsDirectShareCourseOpen={setIsDirectShareCourseOpen}
            setModuleAction={setModuleAction}
            setIsManageModuleContentTrayOpen={setIsManageModuleContentTrayOpen}
            setSourceModule={setSourceModule}
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
      <AddItemModal
        isOpen={isAddItemOpen}
        onRequestClose={() => setIsAddItemOpen(false)}
        moduleName={name}
        moduleId={id}
        itemCount={itemCount || 0}
      />
      {hasActiveOverrides ? (
        <ViewAssignTo
          expanded={expanded}
          isMenuOpen={isMenuOpen}
          moduleId={id}
          moduleName={name}
          prerequisites={prerequisites}
        />
      ) : null}
    </>
  )
}

export default ModuleHeaderActionPanel
