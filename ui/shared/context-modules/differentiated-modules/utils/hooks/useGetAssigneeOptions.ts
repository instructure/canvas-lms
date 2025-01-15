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

import {useMemo} from 'react'
import {useQuery} from '@canvas/query'
import {getSections, getStudents, getGroups} from './queryFn'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {AssigneeOption} from '../../react/Item/types'
import {uniqBy} from 'lodash'

const I18n = createI18nScope('differentiated_modules')

type Props = {
  allOptions: AssigneeOption[]
  courseId: string
  defaultOptions: AssigneeOption[]
  groupCategoryId?: string | null
  shouldFetch: boolean
  params: Record<string, string | number>
  setHasErrors: (value: boolean) => void
}

export const useGetAssigneeOptions = ({
  allOptions,
  courseId,
  defaultOptions,
  groupCategoryId,
  shouldFetch,
  params,
  setHasErrors,
}: Props) => {
  const {data: sectionsParsedResult, isFetching: isSectionsLoading} = useQuery({
    queryKey: ['sections', courseId, params],
    queryFn: getSections,
    enabled: shouldFetch,
    onError: () => {
      showFlashError(I18n.t('An error occurred while fetching sections'))
      setHasErrors(true)
    },
  })

  const {data: studentsParsedResult, isFetching: isStudentsLoading} = useQuery({
    queryKey: ['students', courseId, params],
    queryFn: getStudents,
    enabled: shouldFetch,
    onError: () => {
      showFlashError(I18n.t('An error occurred while fetching students'))
      setHasErrors(true)
    },
    // Override the staleTime and cacheTime values to 15 minutes. This will make newly
    // enrolled students available after few minutes of being added to the course
    staleTime: 15 * (60 * 1000),
    cacheTime: 15 * (60 * 1000),
  })

  const {data: groupsParsedResult, isFetching: isGroupsLoading} = useQuery({
    queryKey: ['groups', groupCategoryId, params],
    queryFn: getGroups,
    enabled: shouldFetch && !!groupCategoryId,
    onError: () => {
      showFlashError(I18n.t('An error occurred while fetching groups'))
      setHasErrors(true)
    },
  })

  const baseFetchedOptions = useMemo(() => {
    const combinedOptions = [
      ...(sectionsParsedResult ?? []),
      ...(groupsParsedResult ?? []),
      ...(studentsParsedResult ?? []),
    ]

    return uniqBy(
      [
        ...combinedOptions.map(option => {
          const existing = allOptions.find(o => o.id === option.id)
          if (existing && existing.overrideId) {
            return {...option, overrideId: existing.overrideId}
          }
          return {...option}
        }),
        ...defaultOptions,
      ],
      'id'
    )
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [sectionsParsedResult, groupsParsedResult, studentsParsedResult])

  const isLoading = useMemo(
    () => isSectionsLoading || isStudentsLoading || isGroupsLoading,
    [isSectionsLoading, isStudentsLoading, isGroupsLoading]
  )

  return {
    baseFetchedOptions,
    isLoading,
  }
}
