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

import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashSuccess, showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import {getItemType, renderItemAssignToManager} from '../utils/assignToUtils'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv'
import {QueryClient} from '@tanstack/react-query'
import type {
  ModuleItemContent,
  ModuleAction,
  PerModuleState,
  MenuItemActionState,
} from '../utils/types'
import React from 'react'
import {MODULE_ITEMS, MODULE_ITEMS_ALL, MODULES, MOVE_MODULE_ITEM} from '../utils/constants'
import {dispatchCommandEvent} from './dispatchCommandEvent'

const I18n = createI18nScope('context_modules_v2')

const ENV = window.ENV as GlobalEnv

export const handlePublishToggle = async (
  moduleId: string,
  itemId: string,
  title: string,
  canBeUnpublished: boolean,
  queryClient: QueryClient,
  courseId: string,
  published?: boolean,
) => {
  if (!canBeUnpublished) return

  const newPublishedState = !published

  try {
    await doFetchApi({
      path: `/api/v1/courses/${courseId}/modules/${moduleId}/items/${itemId}`,
      method: 'PUT',
      body: {
        module_item: {published: newPublishedState},
      },
    })

    showFlashSuccess(
      I18n.t('%{title} has been %{publishState}', {
        title: title,
        publishState: newPublishedState ? I18n.t('published') : I18n.t('unpublished'),
      }),
    )()

    queryClient.invalidateQueries({queryKey: [MODULE_ITEMS, moduleId || '']})
    queryClient.invalidateQueries({queryKey: [MODULE_ITEMS_ALL, moduleId || '']})
  } catch (error) {
    showFlashError(
      I18n.t('Failed to change published state for %{title}', {
        title: title,
      }),
    )()
    console.error('Error updating published state:', error)
  }
}

export const handleEdit = (courseId: string, itemId: string) => {
  dispatchCommandEvent({action: 'edit', courseId, moduleItemId: itemId})
}

export const handleSpeedGrader = (
  content: ModuleItemContent | null,
  courseId: string,
  setIsMenuOpen?: (isOpen: boolean) => void,
) => {
  if (
    content?.type?.toLowerCase().includes('assignment') ||
    content?.type?.toLowerCase().includes('quiz')
  ) {
    window.open(
      `/courses/${courseId}/gradebook/speed_grader?assignment_id=${content._id}`,
      '_blank',
      'noopener',
    )
  }
  if (setIsMenuOpen) {
    setIsMenuOpen(false)
  }
}

export const handleAssignTo = (
  content: ModuleItemContent | null,
  courseId: string,
  title: string,
  cursor: string | null,
  setIsMenuOpen?: (isOpen: boolean) => void,
  moduleId?: string,
) => {
  if (!courseId) {
    showFlashError(I18n.t('Course ID is required for assign to functionality'))
    return
  }

  const isCheckpointed = !!(
    content?.type === 'Discussion' &&
    content?.checkpoints &&
    content.checkpoints.length > 0
  )

  renderItemAssignToManager(true, document.activeElement as HTMLElement, {
    courseId,
    moduleItemName: title || 'Untitled Item',
    moduleItemType: getItemType(content?.type),
    moduleItemContentId: content?._id,
    pointsPossible: content?.pointsPossible,
    moduleId,
    isCheckpointed,
    isGraded: !!content?.graded,
    cursor,
  })
  if (setIsMenuOpen) {
    setIsMenuOpen(false)
  }
}

export const handleDuplicate = (
  id: string,
  itemId: string,
  queryClient: QueryClient,
  courseId: string,
  setMenuItemLoadingState: React.Dispatch<
    React.SetStateAction<PerModuleState<MenuItemActionState>>
  >,
  setIsMenuOpen?: (isOpen: boolean) => void,
) => {
  setMenuItemLoadingState(prev => ({...prev, [id]: {type: 'duplicate', state: true}}))

  doFetchApi({
    path: `/api/v1/courses/${courseId}/modules/items/${itemId}/duplicate`,
    method: 'POST',
  })
    .then(() => {
      showFlashSuccess(I18n.t('Item duplicated successfully'))
      queryClient.invalidateQueries({queryKey: [MODULE_ITEMS, id]})
      queryClient.invalidateQueries({queryKey: [MODULE_ITEMS_ALL, id]})
      queryClient.invalidateQueries({queryKey: [MODULES, courseId]})
    })
    .catch(() => {
      showFlashError(I18n.t('Failed to duplicate item'))
    })
    .finally(() => setMenuItemLoadingState(({[id]: _, ...rest}) => rest))

  if (setIsMenuOpen) {
    setIsMenuOpen(false)
  }
}

export const handleMoveTo = (
  moduleId: string,
  moduleTitle: string,
  itemId: string,
  title: string,
  content: ModuleItemContent | null,
  setModuleAction: React.Dispatch<React.SetStateAction<ModuleAction | null>>,
  setSelectedModuleItem: (item: {id: string; title: string} | null) => void,
  setIsManageModuleContentTrayOpen: (isOpen: boolean) => void,
  setIsMenuOpen?: (isOpen: boolean) => void,
  setSourceModule?: React.Dispatch<React.SetStateAction<{id: string; title: string} | null>>,
) => {
  if (setIsMenuOpen) {
    setIsMenuOpen(false)
  }

  setModuleAction(MOVE_MODULE_ITEM)

  if (content && itemId) {
    setSelectedModuleItem({
      id: itemId,
      title: title || '',
    })
  }

  if (setSourceModule && moduleId) {
    setSourceModule({
      id: moduleId,
      title: moduleTitle,
    })
  }

  setIsManageModuleContentTrayOpen(true)
}

export const updateIndent = async (
  itemId: string,
  moduleId: string,
  newIndent: number,
  courseId: string,
  queryClient: QueryClient,
) => {
  try {
    const formData = new FormData()
    formData.append('content_tag[indent]', String(newIndent))
    formData.append('_method', 'PUT')
    formData.append('authenticity_token', 'asdkfjalsdjflaksjedf')

    await doFetchApi({
      path: `/courses/${courseId}/modules/items/${itemId}`,
      method: 'POST',
      body: formData,
      headers: {},
    })

    showFlashSuccess(I18n.t('Item indentation updated'))

    queryClient.invalidateQueries({queryKey: [MODULE_ITEMS, moduleId || '']})
    queryClient.invalidateQueries({queryKey: [MODULE_ITEMS_ALL, moduleId || '']})
  } catch (error) {
    showFlashError(I18n.t('Failed to update item indentation'))
    console.error('Error updating indent:', error)
  }
}

export const handleDecreaseIndent = async (
  itemId: string,
  moduleId: string,
  courseId: string,
  setIsMenuOpen?: (isOpen: boolean) => void,
) => {
  dispatchCommandEvent({action: 'outdent', courseId, moduleId, moduleItemId: itemId})
  if (setIsMenuOpen) {
    setIsMenuOpen(false)
  }
}

export const handleIncreaseIndent = async (
  itemId: string,
  moduleId: string,
  courseId: string,
  setIsMenuOpen?: (isOpen: boolean) => void,
) => {
  dispatchCommandEvent({action: 'indent', courseId, moduleId, moduleItemId: itemId})
  if (setIsMenuOpen) {
    setIsMenuOpen(false)
  }
}

export const handleSendTo = (
  setIsDirectShareOpen: (isOpen: boolean) => void,
  setIsMenuOpen?: (isOpen: boolean) => void,
) => {
  setIsDirectShareOpen(true)
  if (setIsMenuOpen) {
    setIsMenuOpen(false)
  }
}

export const handleCopyTo = (
  setIsDirectShareCourseOpen: (isOpen: boolean) => void,
  setIsMenuOpen?: (isOpen: boolean) => void,
) => {
  setIsDirectShareCourseOpen(true)
  if (setIsMenuOpen) {
    setIsMenuOpen(false)
  }
}

export const handleRemove = (
  moduleId: string,
  itemId: string,
  title: string,
  queryClient: QueryClient,
  courseId: string,
  setIsMenuOpen?: (isOpen: boolean) => void,
  onAfterSuccess?: () => void,
) => {
  if (window.confirm(I18n.t('Are you sure you want to remove this item from the module?'))) {
    doFetchApi({
      path: `/courses/${courseId}/modules/items/${itemId}`,
      method: 'DELETE',
    })
      .then(() => {
        showFlashSuccess(
          I18n.t('%{title} was successfully removed.', {
            title: title,
          }),
        )
        queryClient.invalidateQueries({queryKey: [MODULE_ITEMS, moduleId || '']})
        queryClient.invalidateQueries({queryKey: [MODULE_ITEMS_ALL, moduleId || '']})
        queryClient.invalidateQueries({queryKey: [MODULES, courseId]})
      })
      .then(() => {
        if (onAfterSuccess) onAfterSuccess()
      })
      .catch(() => {
        showFlashError(I18n.t('Failed to remove item'))
      })
  }
  if (setIsMenuOpen) {
    setIsMenuOpen(false)
  }
}

export const handleMasteryPaths = (_id: string, setIsMenuOpen?: (isOpen: boolean) => void) => {
  window.location.href = `${ENV.CONTEXT_URL_ROOT}/modules/items/${_id}/edit_mastery_paths`
  if (setIsMenuOpen) {
    setIsMenuOpen(false)
  }
}
