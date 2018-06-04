/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import I18n from 'i18n!roster'
import React from 'react'
import PropTypes from 'prop-types'
import Alert from '@instructure/ui-alerts/lib/components/Alert'

  class ApiError extends React.Component {
    static propTypes = {
      error: PropTypes.oneOfType([
        PropTypes.string,
        PropTypes.arrayOf(PropTypes.string)
      ]).isRequired
    };

    renderErrorList () {
      return (
        <div className="addpeople__apierror">
          {I18n.t('The following users could not be created.')}
          <ul className="apierror__error_list">
            {
              this.props.error.map(e => <li key={Date.now()}>{e}</li>)
            }
          </ul>
        </div>
      );
    }

    // render the list of login_ids where we did not find users
    render () {
      return (
        <Alert variant="error">
          {Array.isArray(this.props.error) ? this.renderErrorList() : this.props.error}
        </Alert>
      )
    }
  }

export default ApiError
