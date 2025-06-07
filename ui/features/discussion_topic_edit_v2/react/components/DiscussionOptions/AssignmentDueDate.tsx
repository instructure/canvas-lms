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

import React, {useState, useEffect, useRef, useContext} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {DateTimeInput} from '@instructure/ui-date-time-input'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {AssignedTo} from './AssignedTo'
import {DiscussionDueDatesContext} from '../../util/constants'

const I18n = createI18nScope('discussion_create')

interface AssignOption {
  assetCode: string
  label: string
}

interface AssignedInformation {
  dueDateId: string
  assignedList: string[]
  dueDate: string
  availableFrom: string
  availableUntil: string
}

interface AssignmentDueDateProps {
  availableAssignToOptions?: {
    [key: string]: AssignOption[]
  }
  initialAssignedInformation?: AssignedInformation
  onAssignedInfoChange?: (info: AssignedInformation) => void
}

interface FormMessage {
  text: string
  type: 'error' | 'hint' | 'success' | 'screenreader-only'
}

export const AssignmentDueDate: React.FC<AssignmentDueDateProps> = ({
  initialAssignedInformation = {
    dueDateId: '',
    assignedList: [],
    dueDate: '',
    availableFrom: '',
    availableUntil: '',
  },
  availableAssignToOptions = {},
  onAssignedInfoChange = () => {},
}) => {
  const dueAtRef = useRef<any>()
  const unlockAtRef = useRef<any>()

  const [assignedInformation, setAssignedInformation] = useState(initialAssignedInformation)
  const [dueDateErrorMessage, setDueDateErrorMessage] = useState<FormMessage[]>([])
  const [availableFromAndUntilErrorMessage, setAvailableFromAndUntilErrorMessage] = useState<
    FormMessage[]
  >([])

  const {gradedDiscussionRefMap, setGradedDiscussionRefMap} = useContext(
    DiscussionDueDatesContext,
  ) as any

  const validateDueDate = (
    dueDate: string,
    availableFrom: string,
    availableUntil: string,
  ): string | null => {
    const due = new Date(dueDate)
    const from = availableFrom ? new Date(availableFrom) : null
    const until = availableUntil ? new Date(availableUntil) : null

    if (from && due < from) {
      return I18n.t('Due date must not be before the Available From date.')
    }
    if (until && due > until) {
      return I18n.t('Due date must not be after the Available Until date.')
    }
    return null
  }

  const validateAvailableFromAndUntil = (
    availableFrom: string,
    availableUntil: string,
  ): string | null => {
    const from = availableFrom ? new Date(availableFrom) : null
    const until = availableUntil ? new Date(availableUntil) : null

    if (from && until && from > until) {
      return I18n.t('Unlock date cannot be after lock date')
    }
    return null
  }

  const setRefMap = (field: string, ref: any) => {
    const refMap = gradedDiscussionRefMap.get(initialAssignedInformation.dueDateId) || {}
    refMap[field] = ref
    const newMap = new Map(gradedDiscussionRefMap)
    newMap.set(initialAssignedInformation.dueDateId, refMap)
    setGradedDiscussionRefMap(newMap)
  }

  useEffect(() => {
    const {dueDate, availableFrom, availableUntil} = assignedInformation

    const dueDateError = validateDueDate(dueDate, availableFrom, availableUntil)
    const availableFromAndUntilError = validateAvailableFromAndUntil(availableFrom, availableUntil)

    if (dueDateError) {
      setDueDateErrorMessage([
        {
          text: dueDateError,
          type: 'error',
        },
      ])
      setRefMap('dueAtRef', dueAtRef)
    } else {
      setDueDateErrorMessage([])
      setRefMap('dueAtRef', null)
    }

    if (availableFromAndUntilError) {
      setAvailableFromAndUntilErrorMessage([
        {
          text: availableFromAndUntilError,
          type: 'error',
        },
      ])
      setRefMap('unlockAtRef', unlockAtRef)
    } else {
      setAvailableFromAndUntilErrorMessage([])
      setRefMap('unlockAtRef', null)
    }

    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [
    assignedInformation.dueDate,
    assignedInformation.availableFrom,
    assignedInformation.availableUntil,
  ])

  // Form properties
  return (
    <>
      <FormFieldGroup description="" width="100%" data-testid="assignment-due-date">
        <AssignedTo
          dueDateId={initialAssignedInformation.dueDateId}
          availableAssignToOptions={availableAssignToOptions}
          initialAssignedToInformation={initialAssignedInformation.assignedList}
          onOptionSelect={(selectedOption: string) => {
            const newInfo = {
              ...assignedInformation,
              assignedList: [...assignedInformation.assignedList, selectedOption],
            }
            setAssignedInformation(newInfo)
            onAssignedInfoChange(newInfo)
          }}
          onOptionDismiss={(dismissedOption: string) => {
            const newInfo = {
              ...assignedInformation,
              assignedList: assignedInformation.assignedList.filter(
                option => option !== dismissedOption,
              ),
            }
            setAssignedInformation(newInfo)
            onAssignedInfoChange(newInfo)
          }}
        />
        <DateTimeInput
          timezone={ENV.TIMEZONE}
          description={I18n.t('Due')}
          prevMonthLabel={I18n.t('previous')}
          nextMonthLabel={I18n.t('next')}
          onChange={(_event: any, newDate?: string) => {
            const newInfo = {...assignedInformation, dueDate: newDate || ''}
            setAssignedInformation(newInfo)
            onAssignedInfoChange(newInfo)
          }}
          value={assignedInformation.dueDate}
          invalidDateTimeMessage={I18n.t('Invalid date and time')}
          layout="columns"
          datePlaceholder={I18n.t('Select Assignment Due Date')}
          dateRenderLabel={I18n.t('Date')}
          timeRenderLabel={I18n.t('Time')}
          messages={dueDateErrorMessage}
          dateInputRef={(ref: any) => {
            dueAtRef.current = ref
          }}
        />
        <DateTimeInput
          timezone={ENV.TIMEZONE}
          description={I18n.t('Available from')}
          prevMonthLabel={I18n.t('previous')}
          nextMonthLabel={I18n.t('next')}
          onChange={(_event: any, newDate?: string) => {
            const newInfo = {...assignedInformation, availableFrom: newDate || ''}
            setAssignedInformation(newInfo)
            onAssignedInfoChange(newInfo)
          }}
          value={assignedInformation.availableFrom}
          invalidDateTimeMessage={I18n.t('Invalid date and time')}
          layout="columns"
          datePlaceholder={I18n.t('Select Assignment Available From Date')}
          dateRenderLabel={I18n.t('Date')}
          timeRenderLabel={I18n.t('Time')}
          messages={availableFromAndUntilErrorMessage}
          dateInputRef={(ref: any) => {
            unlockAtRef.current = ref
          }}
        />
        <DateTimeInput
          timezone={ENV.TIMEZONE}
          description={I18n.t('Until')}
          prevMonthLabel={I18n.t('previous')}
          nextMonthLabel={I18n.t('next')}
          onChange={(_event: any, newDate?: string) => {
            const newInfo = {...assignedInformation, availableUntil: newDate || ''}
            setAssignedInformation(newInfo)
            onAssignedInfoChange(newInfo)
          }}
          value={assignedInformation.availableUntil}
          invalidDateTimeMessage={I18n.t('Invalid date and time')}
          layout="columns"
          datePlaceholder={I18n.t('Select Assignment Available Until Date')}
          dateRenderLabel={I18n.t('Date')}
          timeRenderLabel={I18n.t('Time')}
          messages={availableFromAndUntilErrorMessage}
        />
      </FormFieldGroup>
    </>
  )
}
