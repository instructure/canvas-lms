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
import {useScope as createI18nScope} from '@canvas/i18n'

import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

import {Text} from '@instructure/ui-text'

import EditableHeading from './EditableHeading'

const I18n = createI18nScope('assignments_2')

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

  // @ts-expect-error
  constructor(props) {
    super(props)

    this.state = {
      isValid: props.onValidate('name', props.name),
    }
  }

  // @ts-expect-error
  static getDerivedStateFromProps(props, state) {
    const isValid = props.onValidate('name', props.name)
    return isValid !== state.isValid ? {isValid} : null
  }

  // @ts-expect-error
  handleNameChange = name => {
    // @ts-expect-error
    const isValid = this.props.onValidate('name', name)
    this.setState({isValid}, () => {
      if (!isValid) {
        showFlashAlert({
          // @ts-expect-error
          message: this.props.invalidMessage('name') || I18n.t('Error'),
          type: 'error',
          srOnly: true,
        })
      }
      // @ts-expect-error
      this.props.onChange(name)
    })
  }

  render() {
    // @ts-expect-error
    const msg = this.state.isValid ? null : (
      <div>
        {/* @ts-expect-error */}
        <Text color="danger">{this.props.invalidMessage('name')}</Text>
      </div>
    )
    return (
      <div data-testid="AssignmentName">
        <EditableHeading
          // @ts-expect-error
          mode={this.props.mode}
          viewAs="div"
          level="h1"
          // @ts-expect-error
          value={this.props.name}
          onChange={this.handleNameChange}
          // @ts-expect-error
          onChangeMode={this.props.onChangeMode}
          placeholder={namePlaceholder}
          label={nameLabel}
          required={true}
          // @ts-expect-error
          readOnly={this.props.readOnly}
        />
        {msg}
      </div>
    )
  }
}
