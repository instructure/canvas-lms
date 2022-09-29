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
import CustomHelpLinkPropTypes from './CustomHelpLinkPropTypes'

export default class CustomHelpLinkAction extends React.Component {
  static propTypes = {
    link: CustomHelpLinkPropTypes.link.isRequired,
    label: PropTypes.string.isRequired,
    iconClass: PropTypes.string.isRequired,
    onClick: PropTypes.func,
  }

  static defaultProps = {
    onClick: null,
  }

  handleClick = e => {
    if (typeof this.props.onClick === 'function') {
      this.props.onClick(this.props.link)
    } else {
      e.preventDefault()
    }
  }

  focus = () => {
    if (this.node && !this.node.disabled) {
      this.node.focus()
    }
  }

  render() {
    return (
      <button
        type="button"
        className="Button Button--icon-action ic-Sortable-sort-controls__button"
        onClick={this.handleClick}
        disabled={this.props.onClick ? null : true}
        ref={c => {
          this.node = c
        }}
      >
        <span className="screenreader-only">{this.props.label}</span>
        <i className={this.props.iconClass} aria-hidden="true" />
      </button>
    )
  }
}
