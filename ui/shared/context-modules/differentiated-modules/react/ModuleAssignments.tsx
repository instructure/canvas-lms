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
import AssigneeSelector, {type AssigneeOption} from './AssigneeSelector'
import type {FormMessage} from '@instructure/ui-form-field'

export interface ModuleAssignmentsProps {
  courseId: string
  onSelect: (options: AssigneeOption[]) => void
  defaultValues: AssigneeOption[]
  onDismiss?: () => void
  onBlur?: () => void
  messages?: FormMessage[]
  inputRef?: (inputElement: HTMLInputElement | null) => void
}

export type {AssigneeOption} from './AssigneeSelector'

export default function ModuleAssignments({
  courseId,
  onSelect,
  defaultValues,
  onDismiss,
  onBlur,
  messages,
  inputRef,
}: ModuleAssignmentsProps) {
  const [selectedOptions, setSelectedOptions] = useState<AssigneeOption[]>(defaultValues)

  const handleSelect = useCallback(
    (assignees: AssigneeOption[]) => {
      setSelectedOptions(assignees)
      onSelect(assignees)
    },
    [onSelect]
  )

  useEffect(() => {
    handleSelect(defaultValues)
  }, [defaultValues, handleSelect])

  return (
    <AssigneeSelector
      courseId={courseId}
      onSelect={handleSelect}
      defaultValues={defaultValues}
      selectedOptionIds={selectedOptions.map(({id}) => id)}
      onError={onDismiss}
      showVisualLabel={false}
      inputRef={inputRef}
      onBlur={onBlur}
      messages={messages}
    />
  )
}
