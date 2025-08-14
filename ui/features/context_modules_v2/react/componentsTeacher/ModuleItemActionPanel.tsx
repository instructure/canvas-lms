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
  handleEdit,
  handleSpeedGrader,
  handleAssignTo,
  handleDuplicate,
  handleMoveTo,
  handleDecreaseIndent,
  handleIncreaseIndent,
  handleSendTo,
  handleCopyTo,
  handleRemove,
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
import {mapContentSelection, mapContentTypeForSharing} from '../utils/utils'
import BlueprintLockIcon from './BlueprintLockIcon'
import EditItemModal from './EditItemModal'
import PublishCloud from '@canvas/files/react/components/PublishCloud'
import ModuleFile from '@canvas/files/backbone/models/ModuleFile'

const I18n = createI18nScope('context_modules_v2')

interface ModuleItemActionPanelProps {
  moduleId: string
  itemId: string
  id: string
  title: string
  newTab?: boolean
  indent: number
  content: ModuleItemContent
  masterCourseRestrictions: ModuleItemMasterCourseRestrictionType | null
  published: boolean
  canBeUnpublished: boolean
  masteryPathsData: MasteryPathsData | null
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
  newTab,
  indent,
  content,
  masterCourseRestrictions,
  published,
  canBeUnpublished,
  masteryPathsData,
  setModuleAction,
  setSelectedModuleItem,
  setIsManageModuleContentTrayOpen,
  setSourceModule,
  moduleTitle = '',
}) => {
  const [isMenuOpen, setIsMenuOpen] = useState(false)
  const [isDirectShareOpen, setIsDirectShareOpen] = useState(false)
  const [isEditItemOpen, setIsEditItemOpen] = useState(false)
  const [isDirectShareCourseOpen, setIsDirectShareCourseOpen] = useState(false)

  const {courseId, isMasterCourse, isChildCourse, setMenuItemLoadingState} = useContextModule()

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
    handleEdit(setIsEditItemOpen)
  }, [setIsEditItemOpen])

  const handleSpeedGraderRef = useCallback(() => {
    handleSpeedGrader(content, courseId, setIsMenuOpen)
  }, [content, courseId, setIsMenuOpen])

  const handleAssignToRef = useCallback(() => {
    handleAssignTo(content, courseId, title, setIsMenuOpen, moduleId)
  }, [content, courseId, setIsMenuOpen, moduleId])

  const handleDuplicateRef = useCallback(() => {
    handleDuplicate(moduleId, itemId, queryClient, courseId, setMenuItemLoadingState, setIsMenuOpen)
  }, [moduleId, itemId, courseId, setIsMenuOpen])

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
    content,
    setModuleAction,
    setSelectedModuleItem,
    setIsManageModuleContentTrayOpen,
    setIsMenuOpen,
    setSourceModule,
  ])

  const handleDecreaseIndentRef = useCallback(() => {
    handleDecreaseIndent(itemId, moduleId, indent, courseId, queryClient, setIsMenuOpen)
  }, [itemId, moduleId, indent, courseId, setIsMenuOpen])

  const handleIncreaseIndentRef = useCallback(() => {
    handleIncreaseIndent(itemId, moduleId, indent, courseId, queryClient, setIsMenuOpen)
  }, [itemId, moduleId, indent, courseId, setIsMenuOpen])

  const handleSendToRef = useCallback(() => {
    handleSendTo(setIsDirectShareOpen, setIsMenuOpen)
  }, [setIsDirectShareOpen, setIsMenuOpen])

  const handleCopyToRef = useCallback(() => {
    handleCopyTo(setIsDirectShareCourseOpen, setIsMenuOpen)
  }, [setIsDirectShareCourseOpen, setIsMenuOpen])

  const handleRemoveRef = useCallback(() => {
    handleRemove(moduleId, itemId, title, queryClient, courseId, setIsMenuOpen)
  }, [moduleId, itemId, content, courseId, setIsMenuOpen])

  const handleMasteryPathsRef = useCallback(() => {
    handleMasteryPaths(itemId, setIsMenuOpen)
  }, [itemId, setIsMenuOpen])

  const publishIconOnClickRef = useCallback(() => {
    handlePublishToggle(moduleId, itemId, title, canBeUnpublished, queryClient, courseId, published)
  }, [moduleId, itemId, content, canBeUnpublished, courseId, published])

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
    }

    return <PublishCloud {...props} model={file} disabled={false} />
  }

  const renderItemPublishButton = () => {
    return (
      <IconButton
        screenReaderLabel={published ? 'Published' : 'Unpublished'}
        renderIcon={published ? IconPublishSolid : IconUnpublishedLine}
        withBackground={false}
        withBorder={false}
        color={published ? 'success' : 'secondary'}
        size="small"
        interaction={canBeUnpublished ? 'enabled' : 'disabled'}
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
        <Flex.Item>{renderPublishButton(content?.type)}</Flex.Item>
        {/* Kebab Menu */}
        <Flex.Item data-testid={`module-item-action-menu_${itemId}`}>
          <ModuleItemActionMenu
            moduleId={moduleId}
            itemType={content?.type || ''}
            content={content}
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
      </Flex>
      {['assignment', 'attachment', 'discussion', 'page', 'quiz', 'module', 'module_item'].includes(
        content?.type?.toLowerCase() || '',
      ) && (
        <>
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
          {content?._id && (
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
      {content && (
        <EditItemModal
          isOpen={isEditItemOpen}
          onRequestClose={() => setIsEditItemOpen(false)}
          itemName={title}
          itemURL={content?.url}
          itemNewTab={newTab}
          itemIndent={indent}
          itemId={itemId}
          itemType={content?.type?.toLowerCase()}
          courseId={courseId}
          moduleId={moduleId}
          masterCourseRestrictions={masterCourseRestrictions}
        />
      )}
    </>
  )
}

export default ModuleItemActionPanel
