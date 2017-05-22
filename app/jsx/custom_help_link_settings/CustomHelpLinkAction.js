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
import ReactDOM from 'react-dom'
import CustomHelpLinkPropTypes from './CustomHelpLinkPropTypes'

  const CustomHelpLinkAction = React.createClass({
    propTypes: {
      link: CustomHelpLinkPropTypes.link.isRequired,
      label: React.PropTypes.string.isRequired,
      iconClass: React.PropTypes.string.isRequired,
      onClick: React.PropTypes.func
    },
    handleClick (e) {
      if (typeof this.props.onClick === 'function') {
        this.props.onClick(this.props.link)
      } else {
        e.preventDefault();
      }
    },
    focus () {
      const node = ReactDOM.findDOMNode(this);

      if (node && !node.disabled) {
        node.focus();
      }
    },
    render () {
      return (
        <button
          type="button"
          className="Button Button--icon-action ic-Sortable-sort-controls__button"
          onClick={this.handleClick}
          disabled={this.props.onClick ? null : true}
        >
          <span className="screenreader-only">
            {this.props.label}
          </span>
          <i className={this.props.iconClass} aria-hidden="true"></i>
        </button>
      )
    }
  });

export default CustomHelpLinkAction
