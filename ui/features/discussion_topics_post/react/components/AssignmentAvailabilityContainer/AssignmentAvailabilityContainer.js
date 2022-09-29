/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'

import {AssignmentSingleAvailabilityWindow} from '../AssignmentSingleAvailabilityWindow/AssignmentSingleAvailabilityWindow'
import {AssignmentMultipleAvailabilityWindows} from '../AssignmentMultipleAvailabilityWindows/AssignmentMultipleAvailabilityWindows'
import PropTypes from 'prop-types'
import React, {useState} from 'react'
import CoursePacingNotice from '@canvas/due-dates/react/CoursePacingNotice'
import {TrayDisplayer} from '../TrayDisplayer/TrayDisplayer'
import {DueDateTray} from '../DueDateTray/DueDateTray'

const I18n = useI18nScope('discussion_posts')

export function AssignmentAvailabilityContainer({...props}) {
  const [dueDateTrayOpen, setDueDateTrayOpen] = useState(false)

  let assignmentOverrides = props.assignment?.assignmentOverrides?.nodes || []

  const defaultDateSet =
    !!props.assignment?.dueAt || !!props.assignment?.lockAt || !!props.assignment?.unlockAt

  const singleOverrideWithNoDefault = !defaultDateSet && assignmentOverrides.length === 1

  if (defaultDateSet) {
    assignmentOverrides = props.isAdmin
      ? assignmentOverrides.concat({
          dueAt: props.assignment?.dueAt,
          unlockAt: props.assignment?.unlockAt,
          lockAt: props.assignment?.lockAt,
          title: assignmentOverrides.length > 0 ? I18n.t('Everyone Else') : I18n.t('Everyone'),
          id: props.assignment?.id,
        })
      : [
          {
            dueAt: props.assignment?.dueAt,
            unlockAt: props.assignment?.unlockAt,
            lockAt: props.assignment?.lockAt,
            title: assignmentOverrides.length > 0 ? I18n.t('Everyone Else') : I18n.t('Everyone'),
            id: props.assignment?.id,
          },
        ]
  }

  return (
    <>
      {props.inPacedCourse || (props.isAdmin && assignmentOverrides.length > 1) ? (
        <AssignmentMultipleAvailabilityWindows
          assignmentOverrides={assignmentOverrides}
          onSetDueDateTrayOpen={setDueDateTrayOpen}
        />
      ) : (
        <AssignmentSingleAvailabilityWindow
          assignmentOverrides={assignmentOverrides}
          assignment={props.assignment}
          isAdmin={props.isAdmin}
          singleOverrideWithNoDefault={singleOverrideWithNoDefault}
          onSetDueDateTrayOpen={setDueDateTrayOpen}
        />
      )}
      <TrayDisplayer
        setTrayOpen={setDueDateTrayOpen}
        trayTitle="Due Dates"
        isTrayOpen={dueDateTrayOpen}
        trayComponent={
          props.inPacedCourse ? (
            <CoursePacingNotice courseId={props.courseId} />
          ) : (
            <DueDateTray assignmentOverrides={assignmentOverrides} isAdmin={props.isAdmin} />
          )
        }
      />
    </>
  )
}

AssignmentAvailabilityContainer.propTypes = {
  assignment: PropTypes.object,
  isAdmin: PropTypes.bool,
  inPacedCourse: PropTypes.bool,
  courseId: PropTypes.string,
}
