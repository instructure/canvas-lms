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

import React from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!assignments'

class DueDateRemoveRowLink extends React.Component {
  static propTypes = {
    handleClick: PropTypes.func.isRequired
  }

  render() {
    return (
      <div className="DueDateRow__RemoveRow">
        <button
          className="Button Button--link"
          onClick={this.props.handleClick}
          ref="removeRowIcon"
          href="#"
          title={I18n.t('Remove These Dates')}
          aria-label={I18n.t('Remove These Dates')}
          type="button"
        >
          <i className="icon-x" role="presentation" />
        </button>
      </div>
    )
  }
}

export default DueDateRemoveRowLink
