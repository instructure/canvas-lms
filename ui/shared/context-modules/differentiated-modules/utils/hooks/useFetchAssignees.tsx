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

import {useEffect, useState} from 'react'

import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {type AssigneeOption} from '../../react/AssigneeSelector'
import {uniqBy} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('differentiated_modules')

interface Props {
  courseId: string
  everyoneOption?: AssigneeOption
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
  disableFetch = false,
  everyoneOption,
  checkMasteryPaths = false,
  customAllOptions,
  customIsLoading,
  customSetSearchTerm,
  onError = () => {},
}: Props) => {
  const [searchTerm, setSearchTerm] = useState('')
  const [allOptions, setAllOptions] = useState<AssigneeOption[]>(defaultValues)
  const [isLoading, setIsLoading] = useState(false)
  const [hasErrors, setHasErrors] = useState(false)

  useEffect(() => {
    const params: Record<string, string> = {}
    const shouldSearchTerm = searchTerm.length > 2
    if (
      (shouldSearchTerm || searchTerm === '') &&
      !disableFetch &&
      !isLoading &&
      !customAllOptions
    ) {
      setIsLoading(true)
      if (shouldSearchTerm) {
        params.search_term = searchTerm
      }
      const fetchSections = doFetchApi({
        path: `/api/v1/courses/${courseId}/sections`,
        params,
      })
      const fetchStudents = doFetchApi({
        path: `/api/v1/courses/${courseId}/users`,
        params: {...params, enrollment_type: 'student'},
      })

      const fetchCourseSettings =
        checkMasteryPaths &&
        doFetchApi({
          path: `/api/v1/courses/${courseId}/settings`,
        })

      Promise.allSettled([fetchSections, fetchStudents, fetchCourseSettings].filter(Boolean))
        .then(results => {
          const sectionsResult = results[0]
          const studentsResult = results[1]
          const courseSettingsResult = results[2]
          let sectionsParsedResult: AssigneeOption[] = []
          let studentsParsedResult: AssigneeOption[] = []
          let masteryPathsOption
          if (sectionsResult.status === 'fulfilled') {
            const sectionsJSON = sectionsResult.value.json as Record<string, string>[]
            sectionsParsedResult =
              sectionsJSON?.map(({id, name}: any) => {
                const parsedId = `section-${id}`
                // if an existing override exists for this section, use it so we have its overrideId
                const existing = allOptions.find(option => option.id === parsedId)
                if (existing !== undefined) {
                  return existing
                }
                return {
                  id: parsedId,
                  value: name,
                  group: I18n.t('Sections'),
                }
              }) ?? []
          } else {
            showFlashError(I18n.t('Failed to load sections data'))(sectionsResult.reason)
            setHasErrors(true)
          }

          if (studentsResult.status === 'fulfilled') {
            const studentsJSON = studentsResult.value.json as Record<string, string>[]
            studentsParsedResult =
              studentsJSON?.map(({id, name, sis_user_id}: any) => {
                const parsedId = `student-${id}`
                // if an existing override exists for this student, use it so we have its overrideId
                const existing = allOptions.find(option => option.id === parsedId)
                if (existing !== undefined) {
                  return {
                    ...existing,
                    sisID: sis_user_id,
                  }
                }
                return {
                  id: parsedId,
                  value: name,
                  sisID: sis_user_id,
                  group: I18n.t('Students'),
                }
              }) ?? []
          } else {
            showFlashError(I18n.t('Failed to load students data'))(studentsResult.reason)
            setHasErrors(true)
          }

          if (courseSettingsResult && courseSettingsResult.status === 'fulfilled') {
            if (courseSettingsResult.value.json.conditional_release) {
              masteryPathsOption = {id: 'mastery_paths', value: I18n.t('Mastery Paths')}
            }
          } else if (courseSettingsResult) {
            showFlashError(I18n.t('Failed to load course settings'))(courseSettingsResult.reason)
            setHasErrors(true)
          }

          const defaultOptions = [everyoneOption, masteryPathsOption, ...allOptions].filter(Boolean)
          const newOptions = uniqBy(
            [
              ...defaultOptions.map(option => {
                const sisID = studentsParsedResult.find(student => student.id === option.id)?.sisID
                if (sisID !== undefined) {
                  return {...option, sisID}
                }
                return option
              }),
              ...sectionsParsedResult,
              ...studentsParsedResult,
            ],
            'id'
          )
          setAllOptions(newOptions)
          setIsLoading(false)
        })
        .catch(e => {
          showFlashError(I18n.t('Something went wrong while fetching data'))(e)
          setHasErrors(true)
        })
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [courseId, searchTerm, disableFetch, customAllOptions])

  useEffect(() => {
    // call onError until all the requests have finished to avoid
    // updating the state of unmounted components
    if (!isLoading && hasErrors) {
      onError()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [hasErrors, isLoading])

  useEffect(() => {
    if (everyoneOption !== undefined && !isLoading) {
      const newOptions = [...allOptions]
      const everyoneOptionIndex = allOptions?.findIndex(option => option.id === everyoneOption.id)
      if (everyoneOptionIndex > -1) {
        newOptions[everyoneOptionIndex] = everyoneOption
      } else {
        newOptions.push(everyoneOption)
      }
      setAllOptions(newOptions)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [JSON.stringify(allOptions), everyoneOption, isLoading])

  return {
    allOptions: customAllOptions ?? allOptions,
    isLoading: customIsLoading ?? isLoading,
    setSearchTerm: customSetSearchTerm ?? setSearchTerm,
  }
}

export default useFetchAssignees
