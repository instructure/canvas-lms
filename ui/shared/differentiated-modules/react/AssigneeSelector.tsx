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
import React, {ReactElement, useEffect, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Link} from '@instructure/ui-link'
import {View} from '@instructure/ui-view'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {debounce, uniqBy} from 'lodash'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Spinner} from '@instructure/ui-spinner'

const {Option: CanvasMultiSelectOption} = CanvasMultiSelect as any

const I18n = useI18nScope('differentiated_modules')

interface Props {
  courseId: string
  moduleId: string
}

interface AssignmentOverride {
  context_module_id: string
  id: string
  students: {
    id: string
    name: string
  }[]
  course_section: {
    id: string
    name: string
  }
}

interface Option {
  id: string
  value: string
  group?: string
}

const AssigneeSelector = ({courseId, moduleId}: Props) => {
  const [selectedAssignees, setSelectedAssignees] = useState<Option[]>([])
  const [searchTerm, setSearchTerm] = useState('')
  const [options, setOptions] = useState<Option[]>([])
  const [isLoading, setIsLoading] = useState(false)
  const [isLoadingDefaultValues, setIsLoadingDefaultValues] = useState(false)

  const handleChange = (newSelected: string[]) => {
    const newSelectedSet = new Set(newSelected)
    const selected = options.filter(option => newSelectedSet.has(option.id))
    setSelectedAssignees(selected)
  }

  const handleInputChange = (value: string) => {
    debounce(() => setSearchTerm(value), 300)()
  }

  useEffect(() => {
    setIsLoadingDefaultValues(true)
    doFetchApi({
      path: `/api/v1/courses/${courseId}/modules/${moduleId}/assignment_overrides`,
    })
      .then(({json}: {json: AssignmentOverride[]}) => {
        const parsedOptions = json.reduce((acc: Option[], override) => {
          const overrideOptions =
            override.students?.map(({id, name}) => ({
              id: `student-${id}`,
              value: name,
              group: I18n.t('Students'),
            })) ?? []
          if (override.course_section !== undefined) {
            const sectionId = `section-${override.course_section.id}`
            overrideOptions.push({
              id: sectionId,
              value: override.course_section.name,
              group: I18n.t('Sections'),
            })
          }
          return [...acc, ...overrideOptions]
        }, [])
        setOptions(parsedOptions)
        setSelectedAssignees(parsedOptions)
      })
      .catch((e: Error) => showFlashError(I18n.t('Something went wrong while fetching data'))(e))
      .finally(() => setIsLoadingDefaultValues(false))
  }, [courseId, moduleId])

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
          let sectionsParsedResult = []
          let studentsParsedResult = []
          if (sectionsResult.status === 'fulfilled') {
            sectionsParsedResult = sectionsResult.value.json.map(({id, name}: any) => ({
              id: `section-${id}`,
              value: name,
              group: I18n.t('Sections'),
            }))
          } else {
            showFlashError(I18n.t('Failed to load sections data'))(sectionsResult.reason)
          }

          if (studentsResult.status === 'fulfilled') {
            studentsParsedResult = studentsResult.value.json.map(({id, name}: any) => ({
              id: `student-${id}`,
              value: name,
              group: I18n.t('Students'),
            }))
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

  if (isLoadingDefaultValues) return <Spinner renderTitle="Loading" size="small" />

  return (
    <>
      <CanvasMultiSelect
        data-testid="assignee_selector"
        label={I18n.t('Assign To')}
        size="large"
        selectedOptionIds={selectedAssignees.map(val => val.id)}
        onChange={handleChange}
        renderAfterInput={<></>}
        customOnInputChange={handleInputChange}
        visibleOptionsCount={14}
        isLoading={isLoading}
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
          onClick={() => setSelectedAssignees([])}
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
