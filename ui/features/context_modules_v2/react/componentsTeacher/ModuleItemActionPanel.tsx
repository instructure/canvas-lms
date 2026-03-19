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
import {IconButton} from '@instructure/ui-buttons'
import {IconPublishSolid, IconUnpublishedLine, IconMasteryPathsLine} from '@instructure/ui-icons'
import {
  handlePublishToggle,
  handleSpeedGrader,
  handleAssignTo,
  handleDuplicate,
  handleMoveTo,
  handleDecreaseIndent,
  handleIncreaseIndent,
  handleSendTo,
  handleCopyTo,
  handleMasteryPaths,
} from '../handlers/moduleItemActionHandlers'
import DirectShareUserModal from '@canvas/direct-sharing/react/components/DirectShareUserModal'
import DirectShareCourseTray from '@canvas/direct-sharing/react/components/DirectShareCourseTray'
import {queryClient} from '@canvas/query'
import {Pill} from '@instructure/ui-pill'
import {Link} from '@instructure/ui-link'
import {useScope as createI18nScope} from '@canvas/i18n'
import ModuleItemActionMenu from './ModuleItemActionMenu'
import {
  MasteryPathsData,
  ModuleItemContent,
  ModuleAction,
  ModuleItemMasterCourseRestrictionType,
} from '../utils/types'
import {useContextModule} from '../hooks/useModuleContext'
import {
  focusModuleItemTitleLinkById,
  mapContentSelection,
  mapContentTypeForSharing,
} from '../utils/utils'
import BlueprintLockIcon from './BlueprintLockIcon'
import PublishCloud from '@canvas/files/react/components/PublishCloud'
import ModuleFile from '@canvas/files/backbone/models/ModuleFile'
import {dispatchCommandEvent} from '../handlers/dispatchCommandEvent'
import {MODULE_ITEMS, MODULE_ITEMS_ALL} from '../utils/constants'
import {usePublishing} from '@canvas/context-modules/react/publishing/publishingContext'

const I18n = createI18nScope('context_modules_v2')

interface ModuleItemActionPanelProps {
  moduleId: string
  itemId: string
  id: string
  title: string
  indent: number
  content: ModuleItemContent
  masterCourseRestrictions: ModuleItemMasterCourseRestrictionType | null
  published: boolean
  canBeUnpublished: boolean
  masteryPathsData: MasteryPathsData | null
  focusTargetItemId?: string
  setModuleAction?: React.Dispatch<React.SetStateAction<ModuleAction | null>>
  setSelectedModuleItem?: (item: {id: string; title: string} | null) => void
  setIsManageModuleContentTrayOpen?: (isOpen: boolean) => void
  setSourceModule?: React.Dispatch<React.SetStateAction<{id: string; title: string} | null>>
  moduleTitle?: string
}

const ModuleItemActionPanel: React.FC<ModuleItemActionPanelProps> = ({
  moduleId,
  itemId,
  id: _id,
  title,
  indent,
  content,
  masterCourseRestrictions,
  published,
  canBeUnpublished,
  masteryPathsData,
  focusTargetItemId,
  setModuleAction,
  setSelectedModuleItem,
  setIsManageModuleContentTrayOpen,
  setSourceModule,
  moduleTitle = '',
}) => {
  const [isMenuOpen, setIsMenuOpen] = useState(false)
  const [isDirectShareOpen, setIsDirectShareOpen] = useState(false)
  const [isDirectShareCourseOpen, setIsDirectShareCourseOpen] = useState(false)
  const [isPublishButtonEnabled, setIsPublishButtonEnabled] = useState(true)

  const {
    courseId,
    isMasterCourse,
    isChildCourse,
    setMenuItemLoadingState,
    permissions,
    moduleCursorState,
  } = useContextModule()

  const publishingContext = usePublishing()
  const publishingInProgress = !!publishingContext?.publishingInProgress

  const renderMasteryPathsInfo = () => {
    if (!masteryPathsData || (!masteryPathsData.isTrigger && !masteryPathsData.releasedLabel)) {
      return null
    }

    return (
      <Flex gap="small" data-testid={`mastery-paths-data-${itemId}`}>
        {masteryPathsData.isTrigger && itemId && (
          <Flex.Item>
            <Link
              isWithinText={false}
              href={`${ENV.CONTEXT_URL_ROOT}/modules/items/${itemId}/edit_mastery_paths`}
            >
              {I18n.t('Mastery Paths')}
            </Link>
          </Flex.Item>
        )}
        {masteryPathsData.releasedLabel && (
          <Flex.Item>
            <Pill data-testid={`${masteryPathsData.releasedLabel}-${itemId}`}>
              <IconMasteryPathsLine size="x-small" /> {masteryPathsData.releasedLabel}
            </Pill>
          </Flex.Item>
        )}
      </Flex>
    )
  }

  const handleEditRef = useCallback(() => {
    dispatchCommandEvent({action: 'edit', courseId, moduleId, moduleItemId: itemId})
  }, [courseId, moduleId, itemId])

  const handleSpeedGraderRef = useCallback(() => {
    handleSpeedGrader(content, courseId, setIsMenuOpen)
  }, [content, courseId, setIsMenuOpen])

  const handleAssignToRef = useCallback(() => {
    handleAssignTo(content, courseId, title, moduleCursorState[moduleId], setIsMenuOpen, moduleId)
  }, [content, courseId, title, moduleId])

  const handleDuplicateRef = useCallback(() => {
    handleDuplicate(moduleId, itemId, queryClient, courseId, setMenuItemLoadingState, setIsMenuOpen)
  }, [moduleId, itemId, courseId, setMenuItemLoadingState, setIsMenuOpen])

  const handleMoveToRef = useCallback(() => {
    if (!setModuleAction || !setSelectedModuleItem || !setIsManageModuleContentTrayOpen) return

    handleMoveTo(
      moduleId,
      moduleTitle,
      itemId,
      title,
      content,
      setModuleAction,
      setSelectedModuleItem,
      setIsManageModuleContentTrayOpen,
      setIsMenuOpen,
      setSourceModule,
    )
  }, [
    moduleId,
    moduleTitle,
    itemId,
    title,
    content,
    setModuleAction,
    setSelectedModuleItem,
    setIsManageModuleContentTrayOpen,
    setIsMenuOpen,
    setSourceModule,
  ])

  const handleDecreaseIndentRef = useCallback(() => {
    handleDecreaseIndent(itemId, moduleId, courseId, setIsMenuOpen)
  }, [itemId, moduleId, courseId, setIsMenuOpen])

  const handleIncreaseIndentRef = useCallback(() => {
    handleIncreaseIndent(itemId, moduleId, courseId, setIsMenuOpen)
  }, [itemId, moduleId, courseId, setIsMenuOpen])

  const handleSendToRef = useCallback(() => {
    handleSendTo(setIsDirectShareOpen, setIsMenuOpen)
  }, [setIsDirectShareOpen, setIsMenuOpen])

  const handleCopyToRef = useCallback(() => {
    handleCopyTo(setIsDirectShareCourseOpen, setIsMenuOpen)
  }, [setIsDirectShareCourseOpen, setIsMenuOpen])

  const handleRemoveRef = useCallback(() => {
    dispatchCommandEvent({
      action: 'remove',
      courseId,
      moduleId,
      moduleItemId: itemId,
      setIsMenuOpen,
      onAfterSuccess: () => focusModuleItemTitleLinkById(focusTargetItemId),
    })
  }, [moduleId, itemId, courseId, focusTargetItemId, setIsMenuOpen])

  const handleMasteryPathsRef = useCallback(() => {
    handleMasteryPaths(itemId, setIsMenuOpen)
  }, [itemId, setIsMenuOpen])

  const publishIconOnClickRef = useCallback(async () => {
    setIsPublishButtonEnabled(false)
    await handlePublishToggle(
      moduleId,
      itemId,
      title,
      canBeUnpublished,
      queryClient,
      courseId,
      published,
    )
    setIsPublishButtonEnabled(true)
  }, [moduleId, itemId, title, canBeUnpublished, courseId, published])

  const renderFilePublishButton = () => {
    const file = new ModuleFile({
      type: 'file',
      id: content?._id,
      locked: content?.locked,
      hidden: content?.fileState === 'hidden',
      unlock_at: content?.unlockAt,
      lock_at: content?.lockAt,
      display_name: title,
      thumbnail_url: content?.thumbnailUrl,
      module_item_id: parseInt(itemId),
      published: published,
    })

    const props = {
      userCanEditFilesForContext: ENV.MODULE_FILE_PERMISSIONS?.manage_files_edit ?? false,
      usageRightsRequiredForContext: ENV.MODULE_FILE_PERMISSIONS?.usage_rights_required,
      fileName: content?.displayName,
      onPublishChange: () => {
        queryClient.invalidateQueries({queryKey: [MODULE_ITEMS, moduleId || '']})
        queryClient.invalidateQueries({queryKey: [MODULE_ITEMS_ALL, moduleId || '']})
      },
    }

    return <PublishCloud {...props} model={file} disabled={publishingInProgress} />
  }

  const renderItemPublishButton = () => {
    return (
      <IconButton
        data-testid={`module-item-publish-button-${itemId}`}
        screenReaderLabel={published ? 'Published' : 'Unpublished'}
        renderIcon={published ? IconPublishSolid : IconUnpublishedLine}
        withBackground={false}
        withBorder={false}
        color={published ? 'success' : 'secondary'}
        size="small"
        interaction={
          canBeUnpublished && isPublishButtonEnabled && !publishingInProgress
            ? 'enabled'
            : 'disabled'
        }
        onClick={publishIconOnClickRef}
      />
    )
  }

  const renderPublishButton = (contentType?: string) => {
    if (contentType === 'File') {
      return renderFilePublishButton()
    }

    return renderItemPublishButton()
  }

  return (
    <>
      <Flex alignItems="center" gap="small" wrap="no-wrap" justifyItems="end">
        {/* Mastery Path Info */}
        {renderMasteryPathsInfo()}
        {/* BlueprintLockIcon */}
        {(isMasterCourse || isChildCourse) && !!masterCourseRestrictions && (
          <BlueprintLockIcon
            initialLockState={content?.isLockedByMasterCourse || false}
            contentId={content?._id}
            contentType={content?.type?.toLowerCase() || ''}
          />
        )}
        {/* Publish Icon */}
        {permissions.canEdit && <Flex.Item>{renderPublishButton(content?.type)}</Flex.Item>}
        {/* Kebab Menu */}
        {(permissions.canView || permissions.canDirectShare) && (
          <Flex.Item data-testid={`module-item-action-menu_${itemId}`}>
            <ModuleItemActionMenu
              moduleId={moduleId}
              itemType={content?.type || ''}
              content={content}
              published={published}
              canDuplicate={content?.canDuplicate || false}
              isMenuOpen={isMenuOpen}
              setIsMenuOpen={setIsMenuOpen}
              indent={indent}
              handleEdit={handleEditRef}
              handleSpeedGrader={handleSpeedGraderRef}
              handleAssignTo={handleAssignToRef}
              handleDuplicate={handleDuplicateRef}
              handleMoveTo={handleMoveToRef}
              handleDecreaseIndent={handleDecreaseIndentRef}
              handleIncreaseIndent={handleIncreaseIndentRef}
              handleSendTo={handleSendToRef}
              handleCopyTo={handleCopyToRef}
              handleRemove={handleRemoveRef}
              masteryPathsData={masteryPathsData}
              handleMasteryPaths={handleMasteryPathsRef}
            />
          </Flex.Item>
        )}
      </Flex>
      {[
        'assignment',
        'attachment',
        'discussion',
        'file',
        'page',
        'quiz',
        'module',
        'module_item',
      ].includes(content?.type?.toLowerCase() || '') && (
        <>
          {isDirectShareOpen && (
            <DirectShareUserModal
              id={moduleId}
              open={isDirectShareOpen}
              sourceCourseId={courseId}
              courseId={courseId}
              contentShare={{
                content_type: mapContentTypeForSharing(content?.type || ''),
                content_id: content?._id,
              }}
              onDismiss={() => {
                setIsDirectShareOpen(false)
              }}
            />
          )}
          {isDirectShareCourseOpen && content?._id && (
            <DirectShareCourseTray
              open={isDirectShareCourseOpen}
              sourceCourseId={courseId}
              contentSelection={
                mapContentSelection(content?._id, content?.type?.toLowerCase() || '') || {}
              }
              onDismiss={() => {
                setIsDirectShareCourseOpen(false)
              }}
            />
          )}
        </>
      )}
    </>
  )
}

export default ModuleItemActionPanel
