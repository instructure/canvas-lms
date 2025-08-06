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

import type React from 'react'
import {useState, useEffect, useMemo} from 'react'
import {View} from '@instructure/ui-view'
import PaginatedNavigation from './PaginatedNavigation'
import type {ModuleItem} from '../utils/types'
import {PAGE_SIZE} from '../utils/constants'
import {useModuleItems} from '../hooks/queries/useModuleItems'
import {Spinner} from '@instructure/ui-spinner'
import {Alert} from '@instructure/ui-alerts'
import {ErrorBoundary} from '@sentry/react'
import {Flex} from '@instructure/ui-flex'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useContextModule} from '../hooks/useModuleContext'
import {useModules} from '../hooks/queries/useModules'

const I18n = createI18nScope('context_modules_v2')

export interface ModuleItemListSmartProps {
  moduleId: string
  isExpanded: boolean
  view: string
  isPaginated: boolean
  renderList: (params: {
    moduleItems: ModuleItem[]
    isEmpty?: boolean
    error: string | Error | null
  }) => React.ReactNode
}

const ModuleItemListSmart: React.FC<ModuleItemListSmartProps> = ({
  moduleId,
  isExpanded,
  view,
  renderList,
  isPaginated,
}) => {
  const [pageIndex, setPageIndex] = useState<number>(1)
  const [visibleItems, setVisibleItems] = useState<ModuleItem[]>([])
  const [visiblePageInfo, setVisiblePageInfo] = useState<{
    start: number
    end: number
    total: number
    totalPages: number
  }>()

  const contextModule: any = useContextModule()
  const {courseId} = contextModule
  const setModuleCursorState: (updater: any) => void = useMemo(
    () =>
      typeof contextModule.setModuleCursorState === 'function'
        ? contextModule.setModuleCursorState
        : () => {},
    [contextModule.setModuleCursorState],
  )

  const {getModuleItemsTotalCount} = useModules(courseId, view)
  const totalCount = getModuleItemsTotalCount(moduleId) || 0
  const isEmptyModule = totalCount === 0
  const cursor = getCursor(pageIndex)
  const moduleItemsResult = useModuleItems(moduleId, cursor, isExpanded, view)

  const totalPages = Number.isFinite(totalCount) ? Math.ceil(totalCount / PAGE_SIZE) : 0
  const moduleItems = useMemo(
    () => moduleItemsResult.data?.moduleItems || [],
    [moduleItemsResult.data?.moduleItems],
  )
  const isLoading = moduleItemsResult.isLoading
  const error = moduleItemsResult.error

  function getCursor(page: number): string | null {
    return page > 1 ? btoa(String((page - 1) * PAGE_SIZE)) : null
  }

  useEffect(() => {
    if (isLoading) return

    setVisibleItems(moduleItems)
    const pageCount = moduleItems.length || 0
    const startItem = (pageIndex - 1) * PAGE_SIZE + 1
    const endItem = Math.min(totalCount, pageCount + startItem - 1)

    setVisiblePageInfo({
      start: startItem,
      end: endItem,
      total: totalCount,
      totalPages: totalPages,
    })
  }, [isLoading, moduleItems, pageIndex, totalCount])

  useEffect(() => {
    if (pageIndex <= totalPages || !totalPages) return

    const newPage = Math.max(1, totalPages)
    if (newPage !== pageIndex) {
      setPageIndex(newPage)
      setModuleCursorState((prev: any) => ({
        ...prev,
        [moduleId]: getCursor(newPage),
      }))
    }
  }, [pageIndex, totalPages, moduleId, setModuleCursorState])

  const handlePageChange = (page: number) => {
    setPageIndex(page)
    setModuleCursorState((prev: any) => ({
      ...prev,
      [moduleId]: getCursor(page),
    }))
  }

  const content = (
    <ErrorBoundary fallback={<Alert variant="error">An unexpected error occurred.</Alert>}>
      {renderList({
        moduleItems: !isLoading ? moduleItems : visibleItems,
        isEmpty: isEmptyModule,
        error,
      })}
    </ErrorBoundary>
  )

  if (!isPaginated || totalPages <= 1) return content

  return visiblePageInfo && !isEmptyModule ? (
    <View as="div">
      {content}
      <Flex as="div" justifyItems="center" alignItems="center" margin="small 0 0 0">
        <PaginatedNavigation
          isLoading={isLoading}
          currentPage={pageIndex}
          onPageChange={handlePageChange}
          visiblePageInfo={visiblePageInfo}
        />
      </Flex>
    </View>
  ) : (
    <View as="div" textAlign="center" padding="medium">
      <Spinner renderTitle={I18n.t('Loading module items')} size="large" />
    </View>
  )
}

export default ModuleItemListSmart
