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

import React from 'react'
import PropTypes from 'prop-types'

  const CustomHelpLinkIconInput = React.createClass({
    propTypes: {
      value: PropTypes.string.isRequired,
      children: PropTypes.node.isRequired,
      label: PropTypes.string.isRequired,
      defaultChecked: PropTypes.bool
    },
    getDefaultProps () {
      return {
        checked: false
      }
    },
    render () {
      const {
        value,
        icon,
        label,
        defaultChecked,
        children
      } = this.props
      return (
        <label className="ic-Radio ic-Radio--icon-only" data-icon-value={value}>
          <input type="radio" value={value} name="account[settings][help_link_icon]" defaultChecked={defaultChecked} />
          <span className="ic-Label">
            <span className="screenreader-only">{label}</span>
            {children}
          </span>
        </label>
      )
    }
  });

export default CustomHelpLinkIconInput
