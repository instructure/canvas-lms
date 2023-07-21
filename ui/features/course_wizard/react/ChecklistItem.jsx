/*
 * Copyright (C) 2014 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'
import classnames from 'classnames'

const I18n = useI18nScope('course_wizard')

class ChecklistItem extends React.Component {
  static displayName = 'ChecklistItem'

  static propTypes = {
    onClick: PropTypes.func.isRequired,
    stepKey: PropTypes.string.isRequired,
    title: PropTypes.string.isRequired,
    complete: PropTypes.bool.isRequired,
    isSelected: PropTypes.bool.isRequired,
    id: PropTypes.string.isRequired,
  }

  state = {classNameString: ''}

  classNameString = ''

  UNSAFE_componentWillMount() {
    this.setClassName(this.props)
  }

  UNSAFE_componentWillReceiveProps(nextProps) {
    this.setClassName(nextProps)
  }

  handleClick = event => {
    event.preventDefault()
    this.props.onClick(this.props.stepKey)
  }

  setClassName = props => {
    this.setState({
      classNameString: classnames({
        'ic-wizard-box__content-trigger': true,
        'ic-wizard-box__content-trigger--checked': props.complete,
        'ic-wizard-box__content-trigger--active': props.isSelected,
      }),
    })
  }

  render() {
    const completionMessage = this.props.complete
      ? I18n.t('(Item Complete)')
      : I18n.t('(Item Incomplete)')

    return (
      <li>
        {/* TODO: use InstUI button */}
        {/* eslint-disable-next-line jsx-a11y/anchor-is-valid */}
        <a
          href="#"
          id={this.props.id}
          className={this.state.classNameString}
          onClick={this.handleClick}
          aria-label={`Select task: ${this.props.title}`}
        >
          <span>
            {this.props.title}
            <span className="screenreader-only">{completionMessage}</span>
          </span>
        </a>
      </li>
    )
  }
}

export default ChecklistItem
