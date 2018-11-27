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

import React, {Component} from 'react'
import PropTypes from 'prop-types'

import IconCheckMark from '@instructure/ui-icons/lib/Solid/IconCheckMark'
import IconLock from '@instructure/ui-icons/lib/Solid/IconLock'
import {omitProps} from '@instructure/ui-utils/lib/react/passthroughProps'
import classNames from 'classnames'
import px from '@instructure/ui-utils/lib/px'

class StepItem extends Component {
  static propTypes = {
    status: PropTypes.oneOf(['complete', 'in-progress', 'unavailable']),
    label: PropTypes.oneOfType([PropTypes.func, PropTypes.string]).isRequired,
    icon: PropTypes.element,
    pinSize: PropTypes.string,
    placement: PropTypes.oneOf(['first', 'last', 'interior'])
  }

  static defaultProps = {
    placement: 'interior'
  }

  renderIcon() {
    const Icon = this.props.icon
    if (!Icon && this.props.status === 'complete') {
      return <IconCheckMark color="primary-inverse" />
    } else if (!Icon && this.props.status === 'unavailable') {
      return <IconLock color="error" />
    } else if (typeof this.props.icon === 'function') {
      return <Icon />
    } else if (Icon) {
      return Icon
    } else {
      return null
    }
  }

  pinSize = () => {
    switch (this.props.status) {
      case 'complete':
        return Math.round(px(this.props.pinSize) / 1.5)
      case 'unavailable':
        return Math.round(px(this.props.pinSize) / 1.2)
      case 'in-progress':
        return px(this.props.pinSize)
      default:
        return Math.round(px(this.props.pinSize) / 2.25)
    }
  }

  renderLabel = () => {
    const {label, status} = this.props
    if (typeof label === 'function') {
      return label(status)
    } else {
      return label
    }
  }

  render() {
    const {status, placement} = this.props

    const classes = {
      'step-item-step': true,
      [status]: true,
      [`placement--${placement}`]: true
    }

    return (
      <span className={classNames(classes)} {...omitProps(this.props, StepItem.propTypes)}>
        <span
          className="pinLayout"
          style={{
            height: px(this.props.pinSize)
          }}
        >
          <span
            aria-hidden="true"
            style={{
              width: `${this.pinSize()}px`,
              height: `${this.pinSize()}px`
            }}
            className="step-item-pin"
          >
            {this.renderIcon()}
          </span>
        </span>
        <span className="step-item-label">{this.renderLabel()}</span>
      </span>
    )
  }
}

export default StepItem
