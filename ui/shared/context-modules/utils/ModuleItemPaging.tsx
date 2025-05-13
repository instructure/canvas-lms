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

import React from 'react'
import {Flex} from '@instructure/ui-flex'
import {Pagination} from '@instructure/ui-pagination'
import {View} from '@instructure/ui-view'
import {type PaginationData, type ModuleId} from './types'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ModuleItemsLoadingSpinner} from './ModuleItemsLoadingSpinner'

const I18n = createI18nScope('context_modulespublic')

type ModuleItemPagingProps = {
  moduleId: ModuleId
  isLoading: boolean
  paginationData?: PaginationData
  onPageChange?: (page: number, moduleId: ModuleId) => void
}
export const ModuleItemPaging = ({
  moduleId,
  isLoading,
  paginationData,
  onPageChange,
}: ModuleItemPagingProps) => {
  const renderPagination = () => {
    if (paginationData && paginationData.totalPages > 1 && onPageChange) {
      const {currentPage, totalPages} = {...paginationData}
      return (
        <View as="div">
          <Pagination
            data-testid={`module-${moduleId}-pagination`}
            as="nav"
            margin="none"
            variant="compact"
            labelNext={I18n.t('Next Page')}
            labelPrev={I18n.t('Previous Page')}
            currentPage={currentPage}
            totalPageNumber={totalPages}
            onPageChange={(page: number) => onPageChange(page, moduleId)}
          />
        </View>
      )
    } else {
      return null
    }
  }

  if (!isLoading && (!paginationData || paginationData.totalPages < 2)) return null

  const spinnerPosition: React.CSSProperties = {
    position: 'absolute',
    insetInlineStart: '-3.5em',
    top: '-.25rem',
  }

  return (
    <Flex as="div" justifyItems="center" alignItems="center">
      <Flex.Item>
        <View as="div" position="relative">
          <div
            style={paginationData ? spinnerPosition : {}}
            data-testid={`spinner_container_${moduleId}`}
          >
            <ModuleItemsLoadingSpinner isLoading={isLoading} />
          </div>
          {renderPagination()}
        </View>
      </Flex.Item>
    </Flex>
  )
}

export {type PaginationData}
