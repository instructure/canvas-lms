/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import doFetchApi, {type DoFetchApiResults} from '@canvas/do-fetch-api-effect'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import {getGlobalTemplates} from '@canvas/block-editor/react/assets/globalTemplates'
import type {BlockTemplate} from '../types'
import {mergeTemplates} from './mergeTemplates'
import {transformTemplate} from './transformations'

const I18n = createI18nScope('block-editor')

export const getTemplates = (configs: {
  course_id: string
  drafts?: boolean
  type?: ('page' | 'section' | 'block')[]
  globals_only: boolean
}) => {
  const promiseApi = doFetchApi<BlockTemplate[]>({
    path: `/api/v1/courses/${
      configs.course_id
    }/block_editor_templates?include[]=node_tree&include[]=thumbnail&sort=name${
      configs.drafts ? '&drafts=1' : ''
    }${configs.type ? `&type=${configs.type}` : ''}`,
    method: 'GET',
  })
    .then((response: DoFetchApiResults<BlockTemplate[]>) => {
      return response.json || []
    })
    .then((templates: BlockTemplate[]) => {
      return templates.map(transformTemplate)
    })
    .catch((err: Error) => {
      showFlashError(I18n.t('Cannot get block custom templates'))(err)
    })

  return Promise.allSettled([promiseApi, getGlobalTemplates()]).then(
    ([apiTemplatesResult, globalTemplatesResult]) => {
      return mergeTemplates(
        (apiTemplatesResult as PromiseFulfilledResult<BlockTemplate[]>).value,
        (globalTemplatesResult as PromiseFulfilledResult<BlockTemplate[]>).value.filter(
          template => !configs.type || configs.type.includes(template.template_type),
        ),
      )
    },
  )
}
