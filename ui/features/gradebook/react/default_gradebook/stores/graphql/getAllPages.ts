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

import {flatten} from 'lodash'
import {NextPageInfo} from './PaginatedResult'

export type GetAllPagesCallbacks<TPage, TError = unknown> = {
  onError?: (error: TError) => Promise<void> | void
  onSuccess?: (result: TPage) => Promise<void> | void
}

type GetAllPagesParams<TPage, TResult, TError = unknown> = {
  flattenPages: (pages: TPage[]) => TResult
  getPageInfo: (result: TPage) => NextPageInfo
  query: (after: string) => Promise<TPage>
} & GetAllPagesCallbacks<TPage, TError>

export type GetAllPagesReturnValue<TResult> = Promise<{
  data: TResult
  onSuccessCallbacks: Promise<void>[]
  onErrorCallbacks: Promise<void>[]
}>

export const getAllPages = async <TPage, TResult, TError = unknown>({
  flattenPages,
  getPageInfo,
  onError,
  onSuccess,
  query,
}: GetAllPagesParams<TPage, TResult, TError>): GetAllPagesReturnValue<TResult> => {
  let after = ''
  let hasNextPage = true
  const pages: TPage[] = []

  const onSuccessCallbacks: Promise<void>[] = []
  const onErrorCallbacks: Promise<void>[] = []

  while (hasNextPage) {
    try {
      const res = await query(after)
      pages.push(res)
      const pageInfo = getPageInfo(res)
      hasNextPage = pageInfo.hasNextPage
      // how is endCursor null?
      after = pageInfo.endCursor ?? ''
      const promise = onSuccess?.(res)
      if (promise) onSuccessCallbacks.push(promise)
    } catch (e) {
      const promise = onError?.(e as TError)
      if (promise) onErrorCallbacks.push(promise)
      return Promise.reject(e)
    }
  }
  return {data: flattenPages(pages), onSuccessCallbacks, onErrorCallbacks}
}
