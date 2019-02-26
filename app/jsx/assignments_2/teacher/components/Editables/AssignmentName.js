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

import React from 'react'
import {bool, func, oneOf, string} from 'prop-types'
import I18n from 'i18n!assignments_2'

import {Text} from '@instructure/ui-elements'

import EditableHeading from './EditableHeading'

const nameLabel = I18n.t('Edit assignment name')
const invalidMessage = I18n.t('Assignment name is required')
const namePlaceholder = I18n.t('Assignment name')

const isNameValid = (required, name) => !required || name

export default class AssignmentName extends React.Component {
  static propTypes = {
    mode: oneOf(['view', 'edit']).isRequired,
    name: string,
    onChange: func.isRequired,
    onChangeMode: func.isRequired,
    required: bool,
    readOnly: bool
  }

  static defaultProps = {
    required: true,
    readOnly: false
  }

  constructor(props) {
    super(props)

    this.state = {
      strValue: props.name,
      isValid: isNameValid(this.props.required, props.name)
    }
  }

  static getDerivedStateFromProps(props, state) {
    // if the current state is invalid, don't replace the state
    // it's there to track invalid values
    if (state.isValid) {
      return {
        strValue: props.name,
        isValid: isNameValid(props.required, props.name)
      }
    }
    return null
  }

  handleNameChange = name => {
    const isValid = isNameValid(this.props.required, name)
    this.setState({isValid, strValue: name}, () => {
      if (isValid) {
        this.props.onChange(name)
      }
    })
  }

  isValid = name => isNameValid(this.props.required, name)

  render() {
    const msg = this.state.isValid ? null : (
      <div>
        <Text color="error">{invalidMessage}</Text>
      </div>
    )
    return (
      <div data-testid="AssignmentName">
        <EditableHeading
          mode={this.props.mode}
          viewAs="div"
          level="h1"
          value={this.state.strValue}
          onChange={this.handleNameChange}
          onChangeMode={this.props.onChangeMode}
          isValid={this.isValid}
          placeholder={namePlaceholder}
          label={nameLabel}
          required={this.props.required}
          readOnly={this.props.readOnly}
        />
        {msg}
      </div>
    )
  }
}
