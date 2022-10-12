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
import classNames from 'classnames'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('choose_mastery_path')

const {func, bool} = PropTypes

export default class SelectButton extends React.Component {
  static propTypes = {
    isSelected: bool,
    isDisabled: bool,
    onSelect: func.isRequired,
  }

  onClick = () => {
    const {isSelected, isDisabled} = this.props
    if (!isSelected && !isDisabled) {
      this.props.onSelect()
    }
  }

  render() {
    const {isSelected, isDisabled} = this.props
    const isBadge = isSelected || isDisabled

    const btnClasses = classNames({
      btn: !isBadge,
      'btn-primary': !isBadge,
      'ic-badge': isBadge,
      'cmp-button': true,
      'cmp-button__selected': isSelected,
      'cmp-button__disabled': isDisabled,
    })

    let text = ''

    if (isSelected) {
      text = I18n.t('Selected')
    } else if (isDisabled) {
      text = I18n.t('Unavailable')
    } else {
      text = I18n.t('Select')
    }

    return (
      <button type="button" className={btnClasses} onClick={this.onClick} disabled={isDisabled}>
        {text}
      </button>
    )
  }
}
