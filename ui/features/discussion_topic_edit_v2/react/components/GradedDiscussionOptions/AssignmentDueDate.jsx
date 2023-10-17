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

import React, {useState} from 'react'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {DateTimeInput} from '@instructure/ui-date-time-input'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {AssignedTo} from './AssignedTo'

const I18n = useI18nScope('discussion_create')

export const AssignmentDueDate = ({
  initialAssignedInformation,
  availableAssignToOptions,
  onAssignedInfoChange,
}) => {
  const [assignedInformation, setAssignedInformation] = useState(initialAssignedInformation)

  // Form properties
  return (
    <>
      <FormFieldGroup description="" width="100%" data-testid="assignment-due-date">
        <AssignedTo
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
                option => option.id !== dismissedOption.id
              ),
            }
            setAssignedInformation(newInfo)
            onAssignedInfoChange(newInfo)
          }}
        />
        <DateTimeInput
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
          datePlaceholder={I18n.t('Select Date')}
          dateRenderLabel=""
          timeRenderLabel=""
        />
        <DateTimeInput
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
          datePlaceholder={I18n.t('Select Date')}
          dateRenderLabel=""
          timeRenderLabel=""
        />
        <DateTimeInput
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
          datePlaceholder={I18n.t('Select Date')}
          dateRenderLabel=""
          timeRenderLabel=""
        />
      </FormFieldGroup>
    </>
  )
}

AssignmentDueDate.propTypes = {
  availableAssignToOptions: PropTypes.objectOf(
    PropTypes.arrayOf(
      PropTypes.shape({
        id: PropTypes.string.isRequired,
        label: PropTypes.string.isRequired,
      })
    )
  ).isRequired,
  initialAssignedInformation: PropTypes.shape({
    assignedList: PropTypes.arrayOf(PropTypes.object),
    dueDate: PropTypes.string,
    availableFrom: PropTypes.string,
    availableUntil: PropTypes.string,
  }),
  onAssignedInfoChange: PropTypes.func,
}

AssignmentDueDate.defaultProps = {
  availableAssignToOptions: {},
  initialAssignedInformation: {
    assignedList: [],
    dueDate: '',
    availableFrom: '',
    availableUntil: '',
  },
  onAssignedInfoChange: () => {},
}
