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

import React, {useState, useCallback, useEffect} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {IconButton, Button} from '@instructure/ui-buttons'
import {IconPlusLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import ContextModulesPublishIcon from '@canvas/context-modules/react/ContextModulesPublishIcon'
import DirectShareUserModal from '@canvas/direct-sharing/react/components/DirectShareUserModal'
import DirectShareCourseTray from '@canvas/direct-sharing/react/components/DirectShareCourseTray'
import {queryClient} from '@canvas/query'
import ModuleActionMenu from '../componentsTeacher/ModuleActionMenu'
import {handlePublishComplete} from '../handlers/moduleActionHandlers'
import {Pill} from '@instructure/ui-pill'
import {CompletionRequirement, ModuleAction} from '../utils/types'
import {useContextModule} from '../hooks/useModuleContext'
import {useModules} from '../hooks/queries/useModules'
import AddItemModal from './AddItemModalComponents/AddItemModal'
import ViewAssignTo from './ViewAssignToTrayComponents/ViewAssignTo'
import {usePublishing} from '@canvas/context-modules/react/publishing/publishingContext'

const I18n = createI18nScope('context_modules_v2')

interface ModuleHeaderActionPanelProps {
  id: string
  name: string
  expanded?: boolean
  published?: boolean
  completionRequirements?: CompletionRequirement[]
  requirementCount?: number
  hasActiveOverrides: boolean
  showAll?: boolean
  onToggleShowAll?: (id: string) => void
  setModuleAction?: React.Dispatch<React.SetStateAction<ModuleAction | null>>
  setIsManageModuleContentTrayOpen?: React.Dispatch<React.SetStateAction<boolean>>
  setSourceModule?: React.Dispatch<React.SetStateAction<{id: string; title: string} | null>>
}

const ModuleHeaderActionPanel: React.FC<ModuleHeaderActionPanelProps> = ({
  id,
  name,
  expanded = false,
  published = false,

  completionRequirements,
  requirementCount = null,
  hasActiveOverrides,
  showAll = false,
  onToggleShowAll,
  setModuleAction,
  setIsManageModuleContentTrayOpen,
  setSourceModule,
}) => {
  const [isMenuOpen, setIsMenuOpen] = useState(false)
  const [isDirectShareOpen, setIsDirectShareOpen] = useState(false)
  const [isDirectShareCourseOpen, setIsDirectShareCourseOpen] = useState(false)
  const [isAddItemOpen, setIsAddItemOpen] = useState(false)
  const [isPublishing, setIsPublishing] = useState(false)
  const {courseId, modulesArePaginated, pageSize, permissions} = useContextModule()
  const {getModuleItemsTotalCount} = useModules(courseId, 'teacher')
  const totalCount = getModuleItemsTotalCount(id) || 0

  const publishingContext = usePublishing()

  useEffect(() => {
    setIsPublishing(false)
  }, [published])

  const onPublishCompleteRef = useCallback(() => {
    handlePublishComplete(queryClient, id, courseId)
  }, [id, courseId])

  const handleToggleShowAll = useCallback(() => {
    if (onToggleShowAll) {
      onToggleShowAll(id)
    }
  }, [id, onToggleShowAll])

  return (
    <>
      <Flex gap="small" alignItems="center" justifyItems="end" wrap="wrap">
        {completionRequirements?.length && (
          <Flex.Item>
            <Pill>
              <Text size="medium" weight="bold" data-testid="completion-requirement">
                {requirementCount ? I18n.t('Complete One Item') : I18n.t('Complete All Items')}
              </Text>
            </Pill>
          </Flex.Item>
        )}
        {expanded && modulesArePaginated && (totalCount || 0) > pageSize && (
          <Flex.Item>
            <Button
              size="small"
              display="inline-block"
              onClick={handleToggleShowAll}
              data-testid="show-all-toggle"
              color="secondary"
              themeOverride={{
                borderWidth: '0',
              }}
            >
              {showAll
                ? I18n.t('Show Less')
                : I18n.t('Show All (%{count})', {count: totalCount || 0})}
            </Button>
          </Flex.Item>
        )}
        {permissions.canEdit && (
          <Flex.Item data-testid="module-publish-button">
            <ContextModulesPublishIcon
              courseId={courseId}
              moduleId={id}
              moduleName={name}
              published={published}
              isPublishing={isPublishing || !!publishingContext?.publishingInProgress}
              setIsPublishing={setIsPublishing}
              onPublishComplete={onPublishCompleteRef}
            />
          </Flex.Item>
        )}
        {permissions.canAdd && (
          <Flex.Item>
            <IconButton
              size="small"
              data-testid="add-item-button"
              screenReaderLabel={I18n.t('Add Item')}
              renderIcon={IconPlusLine}
              withBorder={false}
              withBackground={true}
              onClick={() => {
                setIsAddItemOpen(true)
              }}
            />
          </Flex.Item>
        )}
        {(permissions.canView || permissions.canDirectShare) && (
          <Flex.Item>
            <ModuleActionMenu
              expanded={expanded}
              isMenuOpen={isMenuOpen}
              setIsMenuOpen={setIsMenuOpen}
              id={id}
              name={name}
              setIsDirectShareOpen={setIsDirectShareOpen}
              setIsDirectShareCourseOpen={setIsDirectShareCourseOpen}
              setModuleAction={setModuleAction}
              setIsManageModuleContentTrayOpen={setIsManageModuleContentTrayOpen}
              setSourceModule={setSourceModule}
            />
          </Flex.Item>
        )}
      </Flex>
      {isDirectShareOpen && (
        <DirectShareUserModal
          id={id}
          open={isDirectShareOpen}
          sourceCourseId={courseId}
          courseId={courseId}
          contentShare={{content_type: 'module', content_id: id}}
          onDismiss={() => {
            setIsDirectShareOpen(false)
          }}
        />
      )}
      {isDirectShareCourseOpen && (
        <DirectShareCourseTray
          open={isDirectShareCourseOpen}
          sourceCourseId={courseId}
          courseId={courseId}
          contentSelection={{modules: [id]}}
          onDismiss={() => {
            setIsDirectShareCourseOpen(false)
          }}
        />
      )}
      <AddItemModal
        isOpen={isAddItemOpen}
        onRequestClose={() => setIsAddItemOpen(false)}
        moduleName={name}
        moduleId={id}
      />
      {hasActiveOverrides && permissions.canEdit ? (
        <ViewAssignTo expanded={expanded} isMenuOpen={isMenuOpen} moduleId={id} moduleName={name} />
      ) : null}
    </>
  )
}

export default ModuleHeaderActionPanel
