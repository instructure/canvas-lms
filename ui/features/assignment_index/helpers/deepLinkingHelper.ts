/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {reloadPage} from '@canvas/deep-linking/DeepLinking'

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('assignment_index_deep_linking_handlers')

export const alertUserModuleCreatedKey = 'alertUserModuleCreatedByDeepLinking'

export const handleAssignmentIndexDeepLinking = (event: {
  data: {moduleCreated?: boolean; placement?: string}
}) => {
  try {
    sessionStorage.setItem(
      alertUserModuleCreatedKey,
      (
        !!event?.data?.moduleCreated && event?.data?.placement === 'course_assignments_menu'
      ).toString()
    )
    // MDN says to always catch exceptions from setItem, just in case storage is full.
    // The only thing that happens is the user doesn't get alerted, so we can just swallow this
    // eslint-disable-next-line no-empty
  } catch (e: any) {}
  reloadPage()
}

export const alertIfDeepLinkingCreatedModule = () => {
  if (sessionStorage.getItem(alertUserModuleCreatedKey) === 'true') {
    showFlashAlert({
      message: I18n.t(
        'A new module has been created with the content returned from the tool. If you would like to see it, please visit the Modules page.'
      ),
      err: null,
    })
  }
  // Clear session storage, no need to keep this around
  sessionStorage.removeItem(alertUserModuleCreatedKey)
}
