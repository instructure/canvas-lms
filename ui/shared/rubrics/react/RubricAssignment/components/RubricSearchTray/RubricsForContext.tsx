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

import {useState} from 'react'
import {RubricAssociation, Rubric} from '../../../types/rubric'
import {useQuery} from '@tanstack/react-query'
import {getGradingRubricsForContext} from '../../queries'
import {LoadingIndicator} from '@instructure/platform-loading-indicator'
import {Pagination} from '@instructure/ui-pagination'
import {RubricSearchRow} from './RubricSearchRow'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('rubrics_for_context')

type RubricsForContextProps = {
  courseId: string
  selectedAssociation?: RubricAssociation
  selectedContext: string
  search: string
  paginationEnabled: boolean
  onPreview: (rubric: Rubric) => void
  onSelect: (rubricAssociation: RubricAssociation, rubricId: string) => void
}
export const RubricsForContext = ({
  courseId,
  selectedAssociation,
  selectedContext,
  search,
  paginationEnabled,
  onPreview,
  onSelect,
}: RubricsForContextProps) => {
  const [currentPage, setCurrentPage] = useState(1)
  const [prevSearch, setPrevSearch] = useState(search)
  const [prevContext, setPrevContext] = useState(selectedContext)

  if (paginationEnabled && (search !== prevSearch || selectedContext !== prevContext)) {
    setPrevSearch(search)
    setPrevContext(selectedContext)
    setCurrentPage(1)
  }

  const queryKey = paginationEnabled
    ? ['fetchGradingRubricsForContext', courseId, selectedContext, currentPage, search]
    : ['fetchGradingRubricsForContext', courseId, selectedContext]

  const {data, isLoading} = useQuery({
    queryKey,
    queryFn: getGradingRubricsForContext,
  })

  if (isLoading) {
    return <LoadingIndicator />
  }

  const allRubrics = data?.rubrics ?? []
  const rubrics =
    paginationEnabled || !search
      ? allRubrics
      : allRubrics.filter(({rubric}) => rubric.title.toLowerCase().includes(search.toLowerCase()))

  const totalPages = data?.totalPages ?? 1

  return (
    <>
      {rubrics.map(({rubricAssociation, rubric}) => (
        <RubricSearchRow
          key={rubricAssociation.id}
          rubric={rubric}
          checked={selectedAssociation?.id === rubricAssociation.id}
          onPreview={onPreview}
          onSelect={() => {
            rubricAssociation.hidePoints = rubric.hidePoints ?? false
            onSelect(rubricAssociation, rubric.id)
          }}
        />
      ))}
      {paginationEnabled && totalPages > 1 && (
        <Pagination
          as="nav"
          data-testid="rubric-search-pagination"
          margin="small"
          variant="compact"
          labelNext={I18n.t('Next Page')}
          labelPrev={I18n.t('Previous Page')}
          currentPage={currentPage}
          totalPageNumber={totalPages}
          onPageChange={setCurrentPage}
        />
      )}
    </>
  )
}
