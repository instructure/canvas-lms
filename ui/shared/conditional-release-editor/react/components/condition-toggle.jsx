/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import classNames from 'classnames'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('conditional_release')

const {bool, func, object} = PropTypes

export default class ConditionToggle extends React.Component {
  static get propTypes() {
    return {
      isAnd: bool,
      isFake: bool,
      isDisabled: bool,
      path: object,
      handleToggle: func,
    }
  }

  constructor() {
    super()

    this.handleToggle = this.handleToggle.bind(this)
  }

  renderLabel() {
    return this.props.isAnd ? I18n.t('#conditional_release.and', '&') : I18n.t('or')
  }

  renderAriaLabel() {
    return this.props.isDisabled
      ? I18n.t('Splitting disabled: reached maximum of three assignment groups in a scoring range')
      : this.props.isAnd
      ? I18n.t('Click to split set here')
      : I18n.t('Click to merge sets here')
  }

  handleToggle() {
    if (this.props.handleToggle) {
      this.props.handleToggle(this.props.path, this.props.isAnd, this.props.isDisabled)
    }
  }

  render() {
    const toggleClasses = classNames({
      'cr-condition-toggle': true,
      'cr-condition-toggle__and': this.props.isAnd,
      'cr-condition-toggle__or': !this.props.isAnd,
      'cr-condition-toggle__fake': this.props.isFake,
      'cr-condition-toggle__disabled': this.props.isDisabled,
    })

    return (
      <div className={toggleClasses}>
        <button
          type="button"
          className="cr-condition-toggle__button"
          title={this.renderAriaLabel()}
          aria-label={this.renderAriaLabel()}
          aria-disabled={this.props.isDisabled}
          onClick={this.handleToggle}
        >
          {this.renderLabel()}
        </button>
      </div>
    )
  }
}
