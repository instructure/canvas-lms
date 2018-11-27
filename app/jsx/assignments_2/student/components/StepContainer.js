/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import I18n from 'i18n!assignments_2_student_header_date_title'

import React from 'react'
import Steps from '../../shared/Steps'
import StepItem from '../../shared/Steps/StepItem'

function availableStepContainer() {
  return (
    <div className="steps-container">
      <Steps>
        <StepItem label={I18n.t('Avaible')} status="complete" />
        <StepItem
          status="in-progress"
          label={status =>
            status && status !== 'in-progress' ? I18n.t('Uploaded') : I18n.t('Upload')
          }
        />
        <StepItem
          label={status =>
            status && status !== 'in-progress' ? I18n.t('Submitted') : I18n.t('Submit')
          }
        />
        <StepItem
          label={status =>
            status && status !== 'in-progress' ? I18n.t('Graded') : I18n.t('Not Graded')
          }
        />
      </Steps>
    </div>
  )
}

function unavailableStepContainer() {
  return (
    <div className="steps-container">
      <Steps>
        <StepItem label={I18n.t('Unavailable')} status="unavailable" />
        <StepItem label={I18n.t('Upload')} />
        <StepItem label={I18n.t('Submit')} />
        <StepItem label={I18n.t('Not Graded')} />
      </Steps>
    </div>
  )
}

function StepContainer(props) {
  const {assignment} = props

  // TODO render the step-container based on the actual assignment data.
  if (assignment.lockInfo.isLocked) {
    return unavailableStepContainer()
  } else {
    return availableStepContainer()
  }
}

export default React.memo(StepContainer)
