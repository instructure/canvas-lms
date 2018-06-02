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

import {arrayOf, shape, string} from 'prop-types'
import React from 'react'
import I18n from 'i18n!assignments'

export default class FinalGraderSelectMenu extends React.Component {
  static propTypes = {
    availableModerators: arrayOf(shape({name: string.isRequired, id: string.isRequired})).isRequired,
    finalGraderID: string
  }

  static defaultProps = {
    finalGraderID: null
  }

  constructor(props) {
    super(props)
    this.handleSelectFinalGrader = this.handleSelectFinalGrader.bind(this)
    this.state = {selectedValue: this.props.finalGraderID || ''}
  }

  handleSelectFinalGrader({target: {value: selectedValue}}) {
    this.setState({selectedValue})
  }

  render() {
    return (
      <label htmlFor="selected-moderator">
        <strong className="ModeratedGrading__FinalGraderSelectMenuLabelText">
          {I18n.t('Grader that determines final grade')}
        </strong>

        <select
          className="ModeratedGrading__FinalGraderSelectMenu"
          id="selected-moderator"
          name="final_grader_id"
          onChange={this.handleSelectFinalGrader}
          value={this.state.selectedValue}
        >
          {this.state.selectedValue === '' &&
            <option key="select-grader" value="">{I18n.t('Select Grader')}</option>
          }

          {this.props.availableModerators.map(user => (
            <option key={user.id} value={user.id}>
              {user.name}
            </option>
          ))}
        </select>
      </label>
    )
  }
}
