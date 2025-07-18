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

import {RubricAssociation, Rubric} from '../../../types/rubric'
import {useQuery} from '@tanstack/react-query'
import {getGradingRubricsForContext} from '../../queries'
import LoadingIndicator from '@canvas/loading-indicator'
import {RubricSearchRow} from './RubricSearchRow'

type RubricsForContextProps = {
  courseId: string
  selectedAssociation?: RubricAssociation
  selectedContext: string
  search: string
  onPreview: (rubric: Rubric) => void
  onSelect: (rubricAssociation: RubricAssociation, rubricId: string) => void
}
export const RubricsForContext = ({
  courseId,
  selectedAssociation,
  selectedContext,
  search,
  onPreview,
  onSelect,
}: RubricsForContextProps) => {
  const {data: rubricsForContext = [], isLoading: isRubricsLoading} = useQuery({
    queryKey: ['fetchGradingRubricsForContext', courseId, selectedContext],
    queryFn: getGradingRubricsForContext,
  })

  if (isRubricsLoading) {
    return <LoadingIndicator />
  }

  const filteredContextRubrics = rubricsForContext?.filter(({rubric}) =>
    rubric.title.toLowerCase().includes(search.toLowerCase()),
  )

  return (
    <>
      {filteredContextRubrics?.map(({rubricAssociation, rubric}) => (
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
    </>
  )
}
