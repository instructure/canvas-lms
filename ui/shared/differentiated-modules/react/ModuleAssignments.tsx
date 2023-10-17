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

import React, {useCallback, useEffect, useState} from 'react'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useScope} from '@canvas/i18n'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {Spinner} from '@instructure/ui-spinner'
import {AssignmentOverride} from './types'
import AssigneeSelector, {AssigneeOption} from './AssigneeSelector'

const I18n = useScope('differentiated_modules')

interface ModuleAssignmentsProps {
  courseId: string
  moduleId: string
  onSelect: (options: AssigneeOption[]) => void
}

export type {AssigneeOption} from './AssigneeSelector'

export default function ModuleAssignments({courseId, moduleId, onSelect}: ModuleAssignmentsProps) {
  const [isLoadingDefaultValues, setIsLoadingDefaultValues] = useState(true)
  const [defaultValues, setDefaultValues] = useState<AssigneeOption[]>([])
  const [selectedOptions, setSelectedOptions] = useState<AssigneeOption[]>(defaultValues)

  const handleSelect = useCallback(
    (assignees: AssigneeOption[]) => {
      setSelectedOptions(assignees)
      onSelect(assignees)
    },
    [onSelect]
  )

  useEffect(() => {
    setIsLoadingDefaultValues(true)
    doFetchApi({
      path: `/api/v1/courses/${courseId}/modules/${moduleId}/assignment_overrides`,
    })
      .then((data: any) => {
        if (data.json === undefined) return
        const json = data.json as AssignmentOverride[]
        const parsedOptions = json.reduce((acc: AssigneeOption[], override: AssignmentOverride) => {
          const overrideOptions =
            override.students?.map(({id, name}: {id: string; name: string}) => ({
              id: `student-${id}`,
              overrideId: override.id,
              value: name,
              group: I18n.t('Students'),
            })) ?? []
          if (override.course_section !== undefined) {
            const sectionId = `section-${override.course_section.id}`
            overrideOptions.push({
              id: sectionId,
              overrideId: override.id,
              value: override.course_section.name,
              group: I18n.t('Sections'),
            })
          }
          return [...acc, ...overrideOptions]
        }, [])
        setDefaultValues(parsedOptions)
        setSelectedOptions(parsedOptions)
        onSelect(parsedOptions)
      })
      .catch(showFlashError())
      .finally(() => {
        setIsLoadingDefaultValues(false)
      })
  }, [courseId, moduleId, onSelect])

  return (
    <>
      {isLoadingDefaultValues ? (
        <Spinner renderTitle={I18n.t('Loading')} />
      ) : (
        <AssigneeSelector
          courseId={courseId}
          onSelect={handleSelect}
          isLoadingDefaultValues={isLoadingDefaultValues}
          defaultValues={defaultValues}
          selectedOptionIds={selectedOptions.map(({id}) => id)}
        />
      )}
    </>
  )
}
