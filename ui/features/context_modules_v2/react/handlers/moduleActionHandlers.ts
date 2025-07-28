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

import {useScope as createI18nScope} from '@canvas/i18n'
import type {QueryClient} from '@tanstack/react-query'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'

const I18n = createI18nScope('context_modules_v2')

export const handlePublishComplete = (
  queryClient: QueryClient,
  moduleId: string,
  courseId: string,
) => {
  queryClient.invalidateQueries({queryKey: ['modules', courseId || '']})
  queryClient.invalidateQueries({queryKey: ['moduleItems', moduleId || '']})
}

export const handleDelete = (
  id: string,
  name: string,
  queryClient: QueryClient,
  courseId: string,
  setIsMenuOpen?: (isOpen: boolean) => void,
) => {
  if (window.confirm(I18n.t('Are you sure you want to remove this module?'))) {
    doFetchApi({
      path: `/courses/${courseId}/modules/${id}`,
      method: 'DELETE',
    })
      .then(() => {
        showFlashSuccess(
          I18n.t('%{name} was successfully removed.', {
            name: name,
          }),
        )
        queryClient.invalidateQueries({queryKey: ['modules', courseId || '']})
      })
      .catch(() => {
        showFlashError(I18n.t('Failed to remove module'))
      })
  }
  if (setIsMenuOpen) {
    setIsMenuOpen(false)
  }
}

export const handleDuplicate = (
  id: string,
  name: string,
  queryClient: QueryClient,
  courseId: string,
  setIsMenuOpen?: (isOpen: boolean) => void,
) => {
  doFetchApi({
    path: `/api/v1/courses/${courseId}/modules/${id}/duplicate`,
    method: 'POST',
  })
    .then(() => {
      showFlashSuccess(
        I18n.t('%{name} was successfully duplicated.', {
          name: name,
        }),
      )
      queryClient.invalidateQueries({queryKey: ['modules', courseId || '']})
    })
    .catch(() => {
      showFlashError(I18n.t('Failed to duplicate module'))
    })

  if (setIsMenuOpen) {
    setIsMenuOpen(false)
  }
}

export const handleSendTo = (setIsDirectShareOpen: (isOpen: boolean) => void) => {
  setIsDirectShareOpen(true)
}

export const handleCopyTo = (setIsDirectShareCourseOpen: (isOpen: boolean) => void) => {
  setIsDirectShareCourseOpen(true)
}
