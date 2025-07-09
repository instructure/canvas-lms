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

import {useQuery} from '@tanstack/react-query'
import {gql} from 'graphql-tag'
import {executeQuery} from '@canvas/graphql'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import {MODULE_ITEMS_COUNT} from '../../utils/constants'

const I18n = createI18nScope('context_modules_v2')

const MODULE_BY_ID_QUERY = gql`
  query GetModuleById($moduleId: ID!) {
    legacyNode(_id: $moduleId, type: Module) {
      ... on Module {
        id
        _id
        moduleItemsTotalCount
      }
    }
  }
`

interface ModuleByIdResponse {
  legacyNode?: {
    id?: string
    _id?: string
    moduleItemsTotalCount?: number
  }
}

export function useModuleItemsTotalCount(moduleId: string) {
  const queryKey = [MODULE_ITEMS_COUNT, moduleId]

  const queryResult = useQuery<number | null, Error>({
    queryKey,
    queryFn: async () => {
      try {
        const result = await executeQuery<ModuleByIdResponse>(MODULE_BY_ID_QUERY, {
          moduleId,
        })

        if ((result as any).errors) {
          throw new Error(
            ((result as any).errors as Array<{message: string}>).map(e => e.message).join(', '),
          )
        }

        return result.legacyNode?.moduleItemsTotalCount ?? null
      } catch (err) {
        const errorMessage = err instanceof Error ? err.message : String(err)
        showFlashError(I18n.t('Failed to load module item count: %{error}', {error: errorMessage}))
        throw err
      }
    },
    staleTime: 5 * 60 * 1000,
    refetchOnWindowFocus: false,
  })

  const {data, isFetching, ...rest} = queryResult

  return {
    totalCount: data ?? 0,
    isFetching,
    ...rest,
  }
}
