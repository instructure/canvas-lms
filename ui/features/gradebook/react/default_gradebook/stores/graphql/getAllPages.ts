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

import {mapValues} from 'lodash'
import {NextPageInfo} from './PaginatedResult'

export type GetAllPagesCallbacks<TPage, TError = unknown> = {
  onError?: (error: TError) => Promise<void> | void
  onSuccess?: (result: TPage) => Promise<void> | void
}

export type GetAllPagesReturnValue<TResult> = Promise<{
  data: TResult
  onSuccessCallbacks: Promise<void>[]
  onErrorCallbacks: Promise<void>[]
}>

type GetAllPagesSingleParams<TPage, TResult, TError = unknown> = {
  flattenPages: (pages: TPage[]) => TResult
  getPageInfo: (result: TPage) => NextPageInfo
  query: (after: string) => Promise<TPage>
  isMulti?: false
} & GetAllPagesCallbacks<TPage, TError>
type GetAllPagesMultiParams<TPage, TResult, TError = unknown> = {
  flattenPages: (pages: TPage[]) => TResult
  getPageInfo: (result: TPage) => Record<string, NextPageInfo>
  query: (after: Record<string, string | null>) => Promise<TPage>
  isMulti: true
} & GetAllPagesCallbacks<TPage, TError>

type GetAllPagesParams<TPage, TResult, TError = unknown> =
  | GetAllPagesSingleParams<TPage, TResult, TError>
  | GetAllPagesMultiParams<TPage, TResult, TError>

export const getAllPages = async <TPage, TResult, TError = unknown>(
  params: GetAllPagesParams<TPage, TResult, TError>,
): GetAllPagesReturnValue<TResult> => {
  let singleAfter = ''
  // empty object unless the first response arrives
  // if there are more pages, the cursor will be set to endCursor
  // if there are no more pages, cursor will be set to null
  // IMPORTANT: make sure to bypass adding the subquery part if the value is null
  let multiAfter: Record<string, string | null> = {}

  let hasNextPage = true
  const pages: TPage[] = []
  const onSuccessCallbacks: Promise<void>[] = []
  const onErrorCallbacks: Promise<void>[] = []

  while (hasNextPage) {
    try {
      const res = await (params.isMulti ? params.query(multiAfter) : params.query(singleAfter))
      pages.push(res)

      if (params.isMulti) {
        const pageInfo = params.getPageInfo(res)
        hasNextPage = Object.values(pageInfo).some(it => it.hasNextPage)
        multiAfter = mapValues(pageInfo, it => (it.hasNextPage ? it.endCursor : null))
      } else {
        hasNextPage = params.getPageInfo(res)?.hasNextPage ?? false
        singleAfter = params.getPageInfo(res)?.endCursor ?? ''
      }

      const promise = params.onSuccess?.(res)
      if (promise) onSuccessCallbacks.push(promise)
    } catch (e) {
      const promise = params.onError?.(e as TError)
      if (promise) onErrorCallbacks.push(promise)
      return Promise.reject(e)
    }
  }
  return {data: params.flattenPages(pages), onSuccessCallbacks, onErrorCallbacks}
}
