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

import {arrayOf, shape, string, func } from 'prop-types'
import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import $ from 'jquery'

const I18n = createI18nScope('FinalGraderSelectMenu')

export default class FinalGraderSelectMenu extends React.Component {
  static propTypes = {
    availableModerators: arrayOf(shape({name: string.isRequired, id: string.isRequired}))
      .isRequired,
    finalGraderID: string,
    hideErrors: func
  }

  static defaultProps = {
    finalGraderID: null,
  }

  constructor(props) {
    super(props)
    this.state = {selectedValue: this.props.finalGraderID || ''}
  }

  componentDidMount() {
    $(document).on("validateFinalGraderSelectedValue", (_e, data) => {
      this.setValidationError(!!data.error);
    })
  }

  componentWillUnmount() {
    $(document).off("validateFinalGraderSelectedValue")
  }

  setValidationError(validationError) {
    this.setState({
      validationError: validationError
    })
  }

  handleSelectFinalGrader = ({target: {value: selectedValue}}) => {
    if(this.props.hideErrors)
      this.props.hideErrors('final_grader_id_errors')
    this.setState({selectedValue})
  }

  render() {
    return (
      <>
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
            style={{
              borderColor: this.state.validationError ? 'red' : ''
            }}
          >
            {this.state.selectedValue === '' && (
              <option key="select-grader" value="" style={{
                borderColor: this.state.validationError ? 'red' : ''
              }}>
                {I18n.t('Select Grader')}
              </option>
            )}

            {this.props.availableModerators.map(user => (
              <option key={user.id} value={user.id}>
                {user.name}
              </option>
            ))}
          </select>
        </label>
        <View as="div" id="final_grader_id_errors" style={{ paddingBottom: "small" }}></View>
      </>
    )
  }
}
