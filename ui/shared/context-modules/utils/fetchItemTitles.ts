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

import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('context_modules')

const fetchItemTitles = (courseId: string, moduleId: string, otherFields: string[] = []) => {
  try {
    document.body.classList.add('waiting_for_modules')
    const url = `/api/v1/courses/${courseId}/modules/${moduleId}/items?only[]=title${otherFields.map(f => `&only[]=${f}`)}&per_page=1000`
    return fetch(url, {
      headers: new Headers({
        accept: 'application/json+canvas-string-ids',
      }),
    })
      .then((res: Response) => {
        if (!res.ok) {
          throw new Error(res.statusText)
        }
        return res.json()
      })
      .catch((error: unknown) => {
        showFlashAlert({
          message: I18n.t('Failed loading module items'),
          err: error instanceof Error ? error : new Error(String(error)),
          type: 'error',
        })
      })
      .finally(() => {
        document.body.classList.remove('waiting_for_modules')
      })
  } catch (error: unknown) {
    const err = error instanceof Error ? error : new Error(String(error))
    showFlashAlert({message: I18n.t('Failed loading module items'), err, type: 'error'})
    document.body.classList.remove('waiting_for_modules')
    return Promise.reject(err)
  }
}

export {fetchItemTitles}
