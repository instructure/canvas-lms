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

import CanvasMultiSelect from '@canvas/multi-select/react'
import React, {ReactElement, useEffect, useRef, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Link} from '@instructure/ui-link'
import {View} from '@instructure/ui-view'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {debounce, uniqBy} from 'lodash'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {setContainScrollBehavior} from '../utils/assignToHelper'

const {Option: CanvasMultiSelectOption} = CanvasMultiSelect as any

const I18n = useI18nScope('differentiated_modules')

interface Props {
  courseId: string
  onSelect: (options: AssigneeOption[]) => void
  defaultValues: AssigneeOption[]
  selectedOptionIds: string[]
}

export interface AssigneeOption {
  id: string
  value: string
  overrideId?: string
  group?: string
}

const AssigneeSelector = ({courseId, onSelect, defaultValues, selectedOptionIds}: Props) => {
  const [searchTerm, setSearchTerm] = useState('')
  const [options, setOptions] = useState<AssigneeOption[]>(defaultValues)
  const [isLoading, setIsLoading] = useState(false)
  const listElementRef = useRef<HTMLElement | null>(null)
  const [isShowingOptions, setIsShowingOptions] = useState(false)

  useEffect(() => {
    const params: Record<string, string> = {}
    const shouldSearchTerm = searchTerm.length > 2
    if (shouldSearchTerm || searchTerm === '') {
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

      Promise.allSettled([fetchSections, fetchStudents])
        .then(results => {
          const sectionsResult = results[0]
          const studentsResult = results[1]
          let sectionsParsedResult: AssigneeOption[] = []
          let studentsParsedResult: AssigneeOption[] = []
          if (sectionsResult.status === 'fulfilled') {
            const sectionsJSON = sectionsResult.value.json as Record<string, string>[]
            sectionsParsedResult =
              sectionsJSON?.map(({id, name}: any) => {
                const parsedId = `section-${id}`
                // if an existing override exists for this section, use it so we have its overrideId
                const existing = options.find(option => option.id === parsedId)
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
          }

          if (studentsResult.status === 'fulfilled') {
            const studentsJSON = studentsResult.value.json as Record<string, string>[]
            studentsParsedResult =
              studentsJSON?.map(({id, name}: any) => {
                const parsedId = `student-${id}`
                // if an existing override exists for this student, use it so we have its overrideId
                const existing = options.find(option => option.id === parsedId)
                if (existing !== undefined) {
                  return existing
                }
                return {
                  id: parsedId,
                  value: name,
                  group: I18n.t('Students'),
                }
              }) ?? []
          } else {
            showFlashError(I18n.t('Failed to load students data'))(studentsResult.reason)
          }

          const newOptions = uniqBy(
            [...options, ...sectionsParsedResult, ...studentsParsedResult],
            'id'
          )
          setOptions(newOptions)
          setIsLoading(false)
        })
        .catch(e => showFlashError(I18n.t('Something went wrong while fetching data'))(e))
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [courseId, searchTerm])

  const handleSelectOption = () => {
    setIsShowingOptions(false)
  }

  const handleChange = (newSelected: string[]) => {
    const newSelectedSet = new Set(newSelected)
    const selected = options.filter(option => newSelectedSet.has(option.id))
    onSelect(selected)
  }

  const handleInputChange = debounce(value => setSearchTerm(value), 500)

  const handleShowOptions = () => {
    setIsShowingOptions(true)
    setTimeout(() => {
      setContainScrollBehavior(listElementRef.current)
    }, 500)
  }

  return (
    <>
      <CanvasMultiSelect
        data-testid="assignee_selector"
        label={I18n.t('Assign To')}
        size="large"
        selectedOptionIds={selectedOptionIds}
        onChange={handleChange}
        renderAfterInput={<></>}
        customOnInputChange={handleInputChange}
        visibleOptionsCount={10}
        isLoading={isLoading}
        listRef={e => (listElementRef.current = e)}
        isShowingOptions={isShowingOptions}
        customOnRequestShowOptions={handleShowOptions}
        customOnRequestHideOptions={() => setIsShowingOptions(false)}
        customOnRequestSelectOption={handleSelectOption}
        customRenderBeforeInput={tags =>
          tags?.map((tag: ReactElement) => (
            <View
              key={tag.key}
              data-testid="assignee_selector_selected_option"
              as="div"
              display="inline-block"
              margin="xx-small none"
            >
              {tag}
            </View>
          ))
        }
      >
        {options.map(option => {
          return (
            <CanvasMultiSelectOption
              id={option.id}
              value={option.id}
              key={option.id}
              group={option.group}
            >
              {option.value}
            </CanvasMultiSelectOption>
          )
        })}
      </CanvasMultiSelect>
      <View as="div" textAlign="end" margin="small none">
        <Link
          data-testid="clear_selection_button"
          onClick={() => onSelect([])}
          isWithinText={false}
        >
          <span aria-hidden={true}>{I18n.t('Clear All')}</span>
          <ScreenReaderContent>{I18n.t('Clear Assign To')}</ScreenReaderContent>
        </Link>
      </View>
    </>
  )
}

export default AssigneeSelector
