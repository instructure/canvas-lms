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
import {useCallback, useState, useEffect, useMemo} from 'react'
import {View} from '@instructure/ui-view'
import PaginatedNavigation from './PaginatedNavigation'
import type {ModuleItem} from '../utils/types'
import {SHOW_ALL_PAGE_SIZE} from '../utils/constants'
import {useModuleItems} from '../hooks/queries/useModuleItems'
import {useAllModuleItems} from '../hooks/queries/useAllModuleItems'
import {Spinner} from '@instructure/ui-spinner'
import {Alert} from '@instructure/ui-alerts'
import {ErrorBoundary} from '@sentry/react'
import {Flex} from '@instructure/ui-flex'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useContextModule} from '../hooks/useModuleContext'
import {useModules} from '../hooks/queries/useModules'
import {usePageState} from '../hooks/usePageState'

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
  const [pageIndex, setPageIndex] = usePageState(moduleId)
  const [visibleItems, setVisibleItems] = useState<ModuleItem[]>([])
  const [visiblePageInfo, setVisiblePageInfo] = useState<{
    start: number
    end: number
    total: number
    totalPages: number
  }>()
  const [onPageLoaded, setOnPageLoaded] = useState(() => () => {})

  const contextModule: any = useContextModule()
  const {courseId, pageSize} = contextModule
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

  const getCursor = useCallback(
    (page: number): string | null => {
      return page > 1 ? btoa(String((page - 1) * pageSize)) : null
    },
    [pageSize],
  )
  const cursor = getCursor(pageIndex)

  // Always call both hooks to avoid conditional hook calls
  const paginatedResult = useModuleItems(moduleId, cursor, isExpanded, view)
  const allItemsResult = useAllModuleItems(moduleId, isExpanded && !isPaginated, view)

  // Use the appropriate result based on pagination mode
  const moduleItemsResult = isPaginated ? paginatedResult : allItemsResult

  const totalPages = Number.isFinite(totalCount) ? Math.ceil(totalCount / pageSize) : 0
  const moduleItems = useMemo(
    () => moduleItemsResult.data?.moduleItems || [],
    [moduleItemsResult.data?.moduleItems],
  )
  const isLoading = moduleItemsResult.isLoading
  const error = moduleItemsResult.error

  useEffect(() => {
    if (!isLoading && totalCount > 0) {
      setTimeout(() => {
        if (error) {
          showFlashAlert({
            message: I18n.t('Failed loading module items'),
            type: 'error',
            srOnly: false,
          })
        } else {
          showFlashAlert({
            message: I18n.t('All module items loaded'),
            type: 'success',
            srOnly: true,
            politeness: 'assertive',
          })
        }
      }, 300)
    }
  }, [error, isLoading, totalCount])

  // Update visible items when data changes
  useEffect(() => {
    if (!isLoading) {
      setVisibleItems(moduleItems)
    }
  }, [isLoading, moduleItems])

  useEffect(() => {
    if (isLoading) return

    const pageCount = moduleItems.length || 0
    const startItem = (pageIndex - 1) * pageSize + 1
    const endItem = Math.min(totalCount, pageCount + startItem - 1)

    setVisiblePageInfo({
      start: startItem,
      end: endItem,
      total: totalCount,
      totalPages: totalPages,
    })
    onPageLoaded()
  }, [isLoading, moduleItems, onPageLoaded, pageIndex, pageSize, totalCount, totalPages])

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
  }, [pageIndex, totalPages, moduleId, setModuleCursorState, setPageIndex, getCursor])

  const handlePageChange = (page: number) => {
    setPageIndex(page)
    setModuleCursorState((prev: any) => ({
      ...prev,
      [moduleId]: getCursor(page),
    }))
    setOnPageLoaded(() => () => {
      document.activeElement?.closest('.context_module')?.scrollIntoView({block: 'nearest'})
      setOnPageLoaded(() => () => {})
    })
  }

  // Render paginated mode
  const paginatedContent = (
    <ErrorBoundary fallback={<Alert variant="error">An unexpected error occurred.</Alert>}>
      {renderList({
        moduleItems: !isLoading ? moduleItems : visibleItems,
        isEmpty: isEmptyModule,
        error,
      })}
    </ErrorBoundary>
  )

  if (!isPaginated || totalPages <= 1) {
    return paginatedContent
  }

  return visiblePageInfo && !isEmptyModule ? (
    <View as="div">
      {paginatedContent}

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
