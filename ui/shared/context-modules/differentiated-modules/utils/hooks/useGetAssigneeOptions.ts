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

import {useMemo, useEffect} from 'react'
import {getSections, getStudents, getGroups, getDifferentiationTags} from './queryFn'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {AssigneeOption} from '../../react/Item/types'
import {uniqBy} from 'es-toolkit/compat'
import {useQuery} from '@tanstack/react-query'

const I18n = createI18nScope('differentiated_modules')

type Props = {
  allOptions: AssigneeOption[]
  courseId: string
  defaultOptions: AssigneeOption[]
  groupCategoryId?: string | null
  shouldFetch: boolean
  params: Record<string, string | number>
  setHasErrors: (value: boolean) => void
  onGroupCategoryNotFound?: () => void
}

export const useGetAssigneeOptions = ({
  allOptions,
  courseId,
  defaultOptions,
  groupCategoryId,
  shouldFetch,
  params,
  setHasErrors,
  onGroupCategoryNotFound = () => {},
}: Props) => {
  const {
    data: sectionsParsedResult,
    isFetching: isSectionsLoading,
    error: sectionsError,
  } = useQuery({
    queryKey: ['sections', courseId, params],
    queryFn: getSections,
    enabled: shouldFetch,
  })

  const {
    data: studentsParsedResult,
    isFetching: isStudentsLoading,
    error: studentsError,
  } = useQuery({
    queryKey: ['students', courseId, params],
    queryFn: getStudents,
    enabled: shouldFetch,
    // Override the staleTime and cacheTime values to 15 minutes. This will make newly
    // enrolled students available after few minutes of being added to the course
    staleTime: 15 * (60 * 1000),
    gcTime: 15 * (60 * 1000),
  })

  const {
    data: groupsParsedResult,
    isFetching: isGroupsLoading,
    error: groupsError,
  } = useQuery({
    queryKey: ['groups', groupCategoryId, params],
    queryFn: getGroups,
    enabled: shouldFetch && !!groupCategoryId,
  })

  const {
    data: differentiationTagsParsedResult,
    isFetching: isDifferentiationTagsLoading,
    error: differentiationTagsError,
  } = useQuery({
    queryKey: ['differentiationTags', ENV?.current_user_id, courseId, params],
    queryFn: getDifferentiationTags,
    enabled: shouldFetch && !!ENV?.current_user_id,
  })

  useEffect(() => {
    if (sectionsError) {
      showFlashError(I18n.t('An error occurred while fetching sections'))
      setHasErrors(true)
    }
  }, [sectionsError, setHasErrors])

  useEffect(() => {
    if (studentsError) {
      showFlashError(I18n.t('An error occurred while fetching students'))
      setHasErrors(true)
    }
  }, [studentsError, setHasErrors])

  useEffect(() => {
    if (groupsError) {
      const isNotFound =
        (groupsError as any)?.response?.status === 404 ||
        (groupsError as any)?.status === 404 ||
        groupsError?.message?.includes('not found')

      if (isNotFound) {
        showFlashError(
          I18n.t(
            'The group set for this assignment no longer exists. Groups will not be available for assignment.',
          ),
        )
        onGroupCategoryNotFound()
      } else {
        showFlashError(I18n.t('An error occurred while fetching groups'))
        setHasErrors(true)
      }
    }
  }, [groupsError, setHasErrors, onGroupCategoryNotFound])

  useEffect(() => {
    if (differentiationTagsError) {
      showFlashError(I18n.t('An error occurred while fetching differentiation tags'))
      setHasErrors(true)
    }
  }, [differentiationTagsError, setHasErrors])

  const baseFetchedOptions = useMemo(() => {
    const combinedOptions = [
      ...(sectionsParsedResult ?? []),
      ...(groupsParsedResult ?? []),
      ...(differentiationTagsParsedResult ?? []),
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
      'id',
    )
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [
    sectionsParsedResult,
    groupsParsedResult,
    studentsParsedResult,
    differentiationTagsParsedResult,
  ])

  const isLoading = useMemo(
    () => isSectionsLoading || isStudentsLoading || isGroupsLoading || isDifferentiationTagsLoading,
    [isSectionsLoading, isStudentsLoading, isGroupsLoading, isDifferentiationTagsLoading],
  )

  const isGroupsNotFound =
    groupsError &&
    // @ts-expect-error: Error object may have response property
    (groupsError?.response?.status === 404 ||
      // @ts-expect-error: Error object may have status property
      groupsError?.status === 404 ||
      groupsError?.message?.includes('not found'))

  const blockingGroupsError = groupsError && !isGroupsNotFound

  return {
    baseFetchedOptions,
    isLoading,
    errors: {
      sectionsError,
      studentsError,
      groupsError,
      differentiationTagsError,
    },
    hasErrors: !!(
      sectionsError ||
      studentsError ||
      blockingGroupsError ||
      differentiationTagsError
    ),
  }
}
