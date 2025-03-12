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
import {IconButton} from '@instructure/ui-buttons'
import {
  IconPublishSolid,
  IconUnpublishedLine,
  IconMasteryPathsLine
} from '@instructure/ui-icons'
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
  handleMasteryPaths
} from '../handlers/moduleItemActionHandlers'
import DirectShareUserModal from '@canvas/direct-sharing/react/components/DirectShareUserModal'
import DirectShareCourseTray from '@canvas/direct-sharing/react/components/DirectShareCourseTray'
import { queryClient } from '@canvas/query'
import {Pill} from '@instructure/ui-pill'
import {Link} from '@instructure/ui-link'
import {useScope as createI18nScope} from '@canvas/i18n'
import ModuleItemActionMenu from './ModuleItemActionMenu'
import {MasteryPathsData} from '../utils/types'
import {useContextModule} from '../hooks/useModuleContext'
import {mapContentSelection} from '../utils/utils'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv'

const ENV = window.ENV as GlobalEnv

const I18n = createI18nScope('context_modules_v2')

interface ModuleItemActionPanelProps {
  moduleId: string
  itemId: string
  id: string
  indent: number
  content: {
    id?: string
    _id?: string
    title?: string
    type?: string
    published?: boolean
    canUnpublish?: boolean
  } | null
  published: boolean
  canBeUnpublished: boolean
  masteryPathsData: MasteryPathsData | null
}

const ModuleItemActionPanel: React.FC<ModuleItemActionPanelProps> = ({
  moduleId,
  itemId,
  id,
  indent,
  content,
  published,
  canBeUnpublished,
  masteryPathsData,
}) => {
  const [isMenuOpen, setIsMenuOpen] = useState(false)
  const [isDirectShareOpen, setIsDirectShareOpen] = useState(false)
  const [isDirectShareCourseOpen, setIsDirectShareCourseOpen] = useState(false)

  const {courseId} = useContextModule()

  const renderMasteryPathsInfo = () => {
    if (!masteryPathsData || (!masteryPathsData.isTrigger && !masteryPathsData.releasedLabel)) {
      return null
    }

    return (
      <Flex gap="small" data-testid={`mastery-paths-data-${itemId}`}>
        {masteryPathsData.isTrigger && itemId && (
          <Flex.Item>
            <Link isWithinText={false} href={`${ENV.CONTEXT_URL_ROOT}/modules/items/${itemId}/edit_mastery_paths`}>
              {I18n.t('Mastery Paths')}
            </Link>
          </Flex.Item>
        )}
        {masteryPathsData.releasedLabel && (
          <Flex.Item>
            <Pill data-testid={`${masteryPathsData.releasedLabel}-${itemId}`}>
              <IconMasteryPathsLine size="x-small" />
              {' '}
              {masteryPathsData.releasedLabel}
            </Pill>
          </Flex.Item>
        )}
      </Flex>
    )
  }

  const handleEditRef = useCallback(() => {
    handleEdit(id, courseId, setIsMenuOpen)
  }, [handleEdit, id, courseId, setIsMenuOpen])

  const handleSpeedGraderRef = useCallback(() => {
    handleSpeedGrader(content, courseId, setIsMenuOpen)
  }, [handleSpeedGrader, content, courseId, setIsMenuOpen])

  const handleAssignToRef = useCallback(() => {
    handleAssignTo(content, courseId, setIsMenuOpen)
  }, [handleAssignTo, content, courseId, setIsMenuOpen])

  const handleDuplicateRef = useCallback(() => {
    handleDuplicate(id, itemId, queryClient, courseId, setIsMenuOpen)
  }, [handleDuplicate, id, itemId, queryClient, courseId, setIsMenuOpen])

  const handleMoveToRef = useCallback(() => {
    handleMoveTo(setIsMenuOpen)
  }, [handleMoveTo, setIsMenuOpen])

  const handleDecreaseIndentRef = useCallback(() => {
    handleDecreaseIndent(itemId, moduleId, indent, courseId, queryClient, setIsMenuOpen)
  }, [handleDecreaseIndent, itemId, moduleId, indent, courseId, queryClient, setIsMenuOpen])

  const handleIncreaseIndentRef = useCallback(() => {
    handleIncreaseIndent(itemId, moduleId, indent, courseId, queryClient, setIsMenuOpen)
  }, [handleIncreaseIndent, itemId, moduleId, indent, courseId,queryClient, setIsMenuOpen])

  const handleSendToRef = useCallback(() => {
    handleSendTo(setIsDirectShareOpen, setIsMenuOpen)
  }, [handleSendTo, setIsDirectShareOpen, setIsMenuOpen])

  const handleCopyToRef = useCallback(() => {
    handleCopyTo(setIsDirectShareCourseOpen, setIsMenuOpen)
  }, [handleCopyTo, setIsDirectShareCourseOpen, setIsMenuOpen])

  const handleRemoveRef = useCallback(() => {
    handleRemove(moduleId, itemId, content, queryClient, courseId, setIsMenuOpen)
  }, [handleRemove, moduleId, itemId, content, queryClient, courseId, setIsMenuOpen])

  const handleMasteryPathsRef = useCallback(() => {
    handleMasteryPaths(masteryPathsData, itemId, setIsMenuOpen)
  }, [handleMasteryPaths, masteryPathsData, itemId, setIsMenuOpen])

  const publishIconOnClickRef = useCallback(() => {
    handlePublishToggle(moduleId, itemId, content, canBeUnpublished, queryClient, courseId)
  }, [handlePublishToggle, moduleId, itemId, content, canBeUnpublished, queryClient, courseId])

  return (
    <>
    <Flex alignItems="center" gap="small" wrap="no-wrap" justifyItems="end">
      {/* Mastery Path Info */}
      {renderMasteryPathsInfo()}
      {/* Publish Icon */}
      <Flex.Item>
        <IconButton
          screenReaderLabel={published ? "Published" : "Unpublished"}
          renderIcon={published ? IconPublishSolid : IconUnpublishedLine}
          withBackground={false}
          withBorder={false}
          color={published ? "success" : "secondary"}
          size="small"
          interaction={canBeUnpublished ? "enabled" : "disabled"}
          onClick={publishIconOnClickRef}
        />
      </Flex.Item>
      {/* Kebab Menu */}
      <Flex.Item>
        <ModuleItemActionMenu
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
    <DirectShareUserModal
        open={isDirectShareOpen}
        sourceCourseId={courseId}
        courseId={courseId}
        contentShare={{content_type: content?.type?.toLowerCase() || '', content_id: itemId}}
        onDismiss={() => {
            setIsDirectShareOpen(false)
          }}
      />
      <DirectShareCourseTray
        open={isDirectShareCourseOpen}
        sourceCourseId={courseId}
        courseId={courseId}
        contentSelection={mapContentSelection(itemId, content?.type?.toLowerCase() || '') || {}}
        onDismiss={() => {
          setIsDirectShareCourseOpen(false)
        }}
      />
      </>
  )
}

export default ModuleItemActionPanel
