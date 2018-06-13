/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import $ from 'jquery'
import I18n from 'i18n!assignments'
import {string} from 'prop-types'
import React from 'react'
import ReactDOM from 'react-dom'
import Alert from '@instructure/ui-alerts/lib/components/Alert'


export default function GroupSubmissionAlert ({groupType}) {
  return (
    <Alert variant="warning" margin="medium 0">
     {I18n.t('Keep in mind, this submission will count for everyone in your %{groupType} group.', {groupType})}
    </Alert>
  )
}

GroupSubmissionAlert.propTypes = {
  groupType: string.isRequired
}

$('.group_submission_alert').each((idx, alertContainer) => {
  ReactDOM.render(
    <GroupSubmissionAlert groupType={alertContainer.getAttribute('data-group-type')} />,
    alertContainer
  )
})
