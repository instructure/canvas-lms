/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import PropTypes from 'prop-types'
import React from 'react'

import Alert from '@instructure/ui-alerts/lib/components/Alert'

const AssignmentAlert = props => {
  const {errorMessage, onDismiss, successMessage} = props
  const ALERT_TIMEOUT = 5000

  return (
    <React.Fragment>
      {errorMessage && (
        <Alert
          variant="error"
          margin="small"
          timeout={ALERT_TIMEOUT}
          liveRegion={() => document.getElementById('flash_screenreader_holder')}
          onDismiss={onDismiss}
        >
          {errorMessage}
        </Alert>
      )}
      {successMessage && (
        <Alert
          screenReaderOnly
          liveRegion={() => document.getElementById('flash_screenreader_holder')}
          onDismiss={onDismiss}
          timeout={ALERT_TIMEOUT}
        >
          {successMessage}
        </Alert>
      )}
    </React.Fragment>
  )
}

AssignmentAlert.propTypes = {
  successMessage: PropTypes.string,
  errorMessage: PropTypes.string,
  onDismiss: PropTypes.func
}

export default AssignmentAlert
