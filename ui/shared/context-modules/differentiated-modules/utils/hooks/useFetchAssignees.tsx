/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {useEffect, useState, useRef, useMemo} from 'react'

import {useGetAssigneeOptions} from './useGetAssigneeOptions'
import {getCourseSettings, CourseSettings} from './queryFn'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {uniqBy} from 'lodash'
import {useScope as createI18nScope} from '@canvas/i18n'
import {type AssigneeOption} from '../../react/Item/types'
import {useQuery} from '@tanstack/react-query'

const I18n = createI18nScope('differentiated_modules')

interface Props {
  courseId: string
  everyoneOption?: AssigneeOption
  groupCategoryId?: string | null
  checkMasteryPaths?: boolean
  disableFetch?: boolean // avoid mutating the state when closing the tray
  defaultValues: AssigneeOption[]
  customAllOptions?: AssigneeOption[]
  customIsLoading?: boolean
  customSetSearchTerm?: (term: string) => void
  onError?: () => void
}

const useFetchAssignees = ({
  courseId,
  defaultValues,
  groupCategoryId = null,
  everyoneOption,
  checkMasteryPaths = false,
  customAllOptions,
  customSetSearchTerm,
  onError = () => {},
}: Props) => {
  // FIXME: This search term should be needs to be used
  const [searchTerm, setSearchTerm] = useState('')
  const [allOptions, setAllOptions] = useState<AssigneeOption[]>(defaultValues)
  const [hasErrors, setHasErrors] = useState(false)
  const groupCategoryRef = useRef<string | null>(null)

  const shouldFetch = !ENV?.IN_PACED_COURSE

  const params: Record<string, string | number> = useMemo(() => {
    return {per_page: 100}
  }, [])

  const {data: fetchedCourseSettings, isSuccess: courseSettingsIsSuccess} =
    useQuery<CourseSettings>({
      queryKey: ['courseSettings', courseId],
      queryFn: getCourseSettings,
      enabled: shouldFetch && checkMasteryPaths,
    })

  const {baseFetchedOptions, isLoading} = useGetAssigneeOptions({
    allOptions,
    courseId,
    defaultOptions: defaultValues,
    groupCategoryId,
    shouldFetch,
    params,
    setHasErrors,
  })

  const baseDefaultOptions = useMemo(() => {
    const defaultOptions = everyoneOption ? [everyoneOption] : []
    if (courseSettingsIsSuccess) {
      const courseSettings = fetchedCourseSettings
      if (courseSettings?.conditional_release) {
        defaultOptions.push({id: 'mastery_paths', value: I18n.t('Mastery Paths')})
      }
    } else if (fetchedCourseSettings) {
      // @ts-expect-error ts-migrate(2531) FIXME: Object is possibly 'null'.
      showFlashError(I18n.t('Failed to load course settings'))(fetchedCourseSettings?.reason)
      setHasErrors(true)
    }

    return defaultOptions
  }, [courseSettingsIsSuccess, everyoneOption, fetchedCourseSettings])

  useEffect(() => {
    const newOptions = uniqBy([...baseDefaultOptions, ...baseFetchedOptions], 'id')

    groupCategoryRef.current = groupCategoryId
    setAllOptions(newOptions)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [baseDefaultOptions, baseFetchedOptions])

  useEffect(() => {
    // call onError until all the requests have finished to avoid
    // updating the state of unmounted components
    if (!isLoading && hasErrors) {
      onError()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [hasErrors, isLoading])

  return {
    allOptions: customAllOptions ?? allOptions,
    isLoading,
    loadedAssignees: true,
    setSearchTerm: customSetSearchTerm ?? setSearchTerm,
  }
}

export default useFetchAssignees
