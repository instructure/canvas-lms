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
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {DateTimeInput} from '@instructure/ui-date-time-input'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {AssignedTo} from './AssignedTo'
import {GradedDiscussionDueDatesContext} from '../../util/constants'

const I18n = useI18nScope('discussion_create')

export const AssignmentDueDate = ({
  initialAssignedInformation,
  availableAssignToOptions,
  onAssignedInfoChange,
}) => {
  const dueAtRef = useRef()
  const unlockAtRef = useRef()

  const [assignedInformation, setAssignedInformation] = useState(initialAssignedInformation)
  const [dueDateErrorMessage, setDueDateErrorMessage] = useState([])
  const [availableFromAndUntilErrorMessage, setAvailableFromAndUntilErrorMessage] = useState([])

  const {gradedDiscussionRefMap, setGradedDiscussionRefMap} = useContext(
    GradedDiscussionDueDatesContext
  )

  const validateDueDate = (dueDate, availableFrom, availableUntil) => {
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

  const validateAvailableFromAndUntil = (availableFrom, availableUntil) => {
    const from = availableFrom ? new Date(availableFrom) : null
    const until = availableUntil ? new Date(availableUntil) : null

    if (from && until && from > until) {
      return I18n.t('Unlock date cannot be after lock date')
    }
    return null
  }

  const setRefMap = (field, ref) => {
    const refMap = gradedDiscussionRefMap.get(initialAssignedInformation.dueDateId)
    refMap[field] = ref
    setGradedDiscussionRefMap(new Map(gradedDiscussionRefMap))
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
          onOptionSelect={selectedOption => {
            const newInfo = {
              ...assignedInformation,
              assignedList: [...assignedInformation.assignedList, selectedOption],
            }
            setAssignedInformation(newInfo)
            onAssignedInfoChange(newInfo)
          }}
          onOptionDismiss={dismissedOption => {
            const newInfo = {
              ...assignedInformation,
              assignedList: assignedInformation.assignedList.filter(
                option => option !== dismissedOption
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
          onChange={(_event, newDate) => {
            const newInfo = {...assignedInformation, dueDate: newDate}
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
          dateInputRef={ref => {
            dueAtRef.current = ref
          }}
        />
        <DateTimeInput
          timezone={ENV.TIMEZONE}
          description={I18n.t('Available from')}
          prevMonthLabel={I18n.t('previous')}
          nextMonthLabel={I18n.t('next')}
          onChange={(_event, newDate) => {
            const newInfo = {...assignedInformation, availableFrom: newDate}
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
          dateInputRef={ref => {
            unlockAtRef.current = ref
          }}
        />
        <DateTimeInput
          timezone={ENV.TIMEZONE}
          description={I18n.t('Until')}
          prevMonthLabel={I18n.t('previous')}
          nextMonthLabel={I18n.t('next')}
          onChange={(_event, newDate) => {
            const newInfo = {...assignedInformation, availableUntil: newDate}
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

AssignmentDueDate.propTypes = {
  availableAssignToOptions: PropTypes.objectOf(
    PropTypes.arrayOf(
      PropTypes.shape({
        assetCode: PropTypes.string.isRequired,
        label: PropTypes.string.isRequired,
      })
    )
  ).isRequired,
  initialAssignedInformation: PropTypes.shape({
    dueDateId: PropTypes.string,
    assignedList: PropTypes.arrayOf(PropTypes.string),
    dueDate: PropTypes.string,
    availableFrom: PropTypes.string,
    availableUntil: PropTypes.string,
  }),
  onAssignedInfoChange: PropTypes.func,
}

AssignmentDueDate.defaultProps = {
  availableAssignToOptions: {},
  initialAssignedInformation: {
    dueDateId: '',
    assignedList: [],
    dueDate: '',
    availableFrom: '',
    availableUntil: '',
  },
  onAssignedInfoChange: () => {},
}
