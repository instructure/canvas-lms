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
import {uniqBy} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import {AssigneeOption} from '../../react/Item/types'

const I18n = useI18nScope('differentiated_modules')

interface Props {
  courseId: string
  everyoneOption?: AssigneeOption
  groupCategoryId?: string | null
  checkMasteryPaths?: boolean
  disableFetch?: boolean // avoid mutating the state when closing the tray
  defaultValues: AssigneeOption[]
  customAllOptions?: AssigneeOption[]
  customIsLoading?: boolean
  requiredOptions?: string[]
  customSetSearchTerm?: (term: string) => void
  onError?: () => void
}

type JSONResult = Record<string, string>[]

const processResult = async (
  result: PromiseSettledResult<{
    json: JSONResult
    link?: {next: {url: string}}
  }> | null,
  key: string,
  groupKey: string,
  allOptions: AssigneeOption[],
  setErrorCallback: (state: boolean) => void
) => {
  let resultParsedResult: AssigneeOption[] = []
  if (result && result.status === 'fulfilled') {
    let resultJSON = result.value.json
    if (result.value.link?.next) {
      resultJSON = await fetchNextPages(result.value.link.next, resultJSON)
    }
    resultParsedResult =
      resultJSON?.map(({id, name, group_category_id: groupCategoryId}) => {
        const parsedId = `${key.toLowerCase()}-${id}`
        // if an existing override exists for this asignee, use it so we have its overrideId
        const existing = allOptions.find(option => option.id === parsedId)
        if (existing !== undefined) {
          return existing
        }
        return {
          id: parsedId,
          value: name,
          groupCategoryId,
          group: I18n.t('%{groupKey}', {groupKey}),
        }
      }) ?? []
  } else if (result) {
    showFlashError(I18n.t('Failed to load %{groupKey} data', {groupKey}))(result.reason)
    setErrorCallback(true)
  }
  return resultParsedResult
}

const fetchNextPages = async (next: {url: string}, results: Record<string, any>[]) => {
  let mergedResults = results
  const {json, link} = await doFetchApi({
    path: next.url,
  })
  mergedResults = [...mergedResults, ...json]
  if (link?.next) {
    mergedResults = await fetchNextPages(link.next, mergedResults)
  }
  return mergedResults
}

const useFetchAssignees = ({
  courseId,
  defaultValues,
  groupCategoryId,
  disableFetch = false,
  everyoneOption,
  checkMasteryPaths = false,
  customAllOptions,
  customIsLoading,
  requiredOptions,
  customSetSearchTerm,
  onError = () => {},
}: Props) => {
  const [searchTerm, setSearchTerm] = useState('')
  const [allOptions, setAllOptions] = useState<AssigneeOption[]>(defaultValues)
  const [isLoading, setIsLoading] = useState(false)
  const [loaded, setLoaded] = useState(false)
  const [hasErrors, setHasErrors] = useState(false)

  useEffect(() => {
    const params: Record<string, string | number> = {per_page: 100}
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
      const fetchSections =
        (!loaded || searchTerm !== '') &&
        doFetchApi({
          path: `/api/v1/courses/${courseId}/sections`,
          params,
        })
      const students =
        requiredOptions?.filter(o => o.includes('student'))?.map(o => o.split('-')[1]) ?? []
      const fetchStudents =
        (!loaded || searchTerm !== '') &&
        doFetchApi({
          path: `/api/v1/courses/${courseId}/users`,
          params:
            students.length > 0 && searchTerm === ''
              ? {...params, enrollment_type: 'student', user_ids: students.join(',')}
              : {...params, enrollment_type: 'student'},
        })

      const fetchCourseSettings =
        !loaded &&
        checkMasteryPaths &&
        doFetchApi({
          path: `/api/v1/courses/${courseId}/settings`,
        })

      const fetchGroups =
        groupCategoryId &&
        doFetchApi({
          path: `/api/v1/group_categories/${groupCategoryId}/groups`,
          params,
        })

      Promise.allSettled(
        [fetchSections, fetchStudents, fetchCourseSettings, fetchGroups].filter(Boolean)
      )
        .then(async results => {
          const sectionsResult = fetchSections ? results[0] : null
          const studentsResult = fetchStudents ? results[1] : null
          const courseSettingsResult = fetchCourseSettings ? results[2] : null
          const groupsResult = fetchGroups ? (loaded ? results[0] : results[3]) : null
          const sectionsParsedResult: AssigneeOption[] = await processResult(
            sectionsResult,
            'section',
            'Sections',
            allOptions,
            setHasErrors
          )
          let studentsParsedResult: AssigneeOption[] = []
          const groupsParsedResult: AssigneeOption[] = await processResult(
            groupsResult,
            'group',
            'Groups',
            allOptions,
            setHasErrors
          )
          let masteryPathsOption
          if (studentsResult && studentsResult.status === 'fulfilled') {
            let studentsJSON = studentsResult.value.json as JSONResult
            if (studentsResult.value.link?.next) {
              studentsJSON = await fetchNextPages(studentsResult.value.link.next, studentsJSON)
            }
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
          } else if (studentsResult) {
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
          const filteredOptions = allOptions.filter(
            option =>
              option.groupCategoryId === undefined || option.groupCategoryId === groupCategoryId
          )
          const defaultOptions = [everyoneOption, masteryPathsOption, ...filteredOptions].filter(
            Boolean
          )
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
              ...groupsParsedResult,
              ...studentsParsedResult,
            ],
            'id'
          )
          setAllOptions(newOptions)
          setIsLoading(false)
          setLoaded(true)
        })
        .catch(e => {
          showFlashError(I18n.t('Something went wrong while fetching data'))(e)
          setHasErrors(true)
        })
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [courseId, searchTerm, disableFetch, customAllOptions, groupCategoryId])

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
    loadedAssignees: loaded,
    setSearchTerm: customSetSearchTerm ?? setSearchTerm,
  }
}

export default useFetchAssignees
