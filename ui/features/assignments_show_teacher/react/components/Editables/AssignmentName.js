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
import {useScope as useI18nScope} from '@canvas/i18n'

import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

import {Text} from '@instructure/ui-text'

import EditableHeading from './EditableHeading'

const I18n = useI18nScope('assignments_2')

const nameLabel = I18n.t('Edit assignment name')
const namePlaceholder = I18n.t('Assignment name')

export default class AssignmentName extends React.Component {
  static propTypes = {
    mode: oneOf(['view', 'edit']).isRequired,
    name: string,
    onChange: func.isRequired,
    onChangeMode: func.isRequired,
    onValidate: func.isRequired,
    invalidMessage: func.isRequired,
    readOnly: bool,
  }

  static defaultProps = {
    readOnly: false,
  }

  constructor(props) {
    super(props)

    this.state = {
      isValid: props.onValidate('name', props.name),
    }
  }

  static getDerivedStateFromProps(props, state) {
    const isValid = props.onValidate('name', props.name)
    return isValid !== state.isValid ? {isValid} : null
  }

  handleNameChange = name => {
    const isValid = this.props.onValidate('name', name)
    this.setState({isValid}, () => {
      if (!isValid) {
        showFlashAlert({
          message: this.props.invalidMessage('name') || I18n.t('Error'),
          type: 'error',
          srOnly: true,
        })
      }
      this.props.onChange(name)
    })
  }

  render() {
    const msg = this.state.isValid ? null : (
      <div>
        <Text color="danger">{this.props.invalidMessage('name')}</Text>
      </div>
    )
    return (
      <div data-testid="AssignmentName">
        <EditableHeading
          mode={this.props.mode}
          viewAs="div"
          level="h1"
          value={this.props.name}
          onChange={this.handleNameChange}
          onChangeMode={this.props.onChangeMode}
          placeholder={namePlaceholder}
          label={nameLabel}
          required={true}
          readOnly={this.props.readOnly}
        />
        {msg}
      </div>
    )
  }
}
