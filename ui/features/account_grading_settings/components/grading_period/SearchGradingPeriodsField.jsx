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
import {debounce} from 'lodash'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('SearchGradingPeriodsField')

export default class SearchGradingPeriodsField extends React.Component {
  static propTypes = {
    changeSearchText: PropTypes.func.isRequired,
  }

  inputRef = React.createRef()

  onChange = event => {
    const trimmedText = event.target.value.trim()
    this.search(trimmedText)
  }

  search = debounce(function (trimmedText) {
    this.props.changeSearchText(trimmedText)
  }, 200)

  render() {
    return (
      <div className="GradingPeriodSearchField ic-Form-control">
        <input
          type="text"
          ref={this.inputRef}
          className="ic-Input"
          placeholder={I18n.t('Search grading periods...')}
          onChange={this.onChange}
        />
      </div>
    )
  }
}
