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

import {FormField} from '@instructure/ui-form-field'
import uid from '@instructure/uid'

import TeacherViewContext from '../TeacherViewContext'
import EditableDateTime from './EditableDateTime'

const I18n = createI18nScope('assignments_2')

const fallbackErrorMessage = I18n.t('Invalid date-time')

export default class AssignmentDate extends React.Component {
  static contextType = TeacherViewContext

  static propTypes = {
    mode: oneOf(['view', 'edit']).isRequired,
    label: string.isRequired,
    onChange: func.isRequired,
    onChangeMode: func.isRequired,
    onValidate: func.isRequired,
    invalidMessage: func.isRequired,
    value: string,
    readOnly: bool,
  }

  static defaultProps = {
    readOnly: false,
  }

  // @ts-expect-error
  constructor(props) {
    super(props)

    this.state = {
      isValid: props.onValidate(props.value),
    }
    // @ts-expect-error
    this.id = uid() // FormField reqires an id
  }

  // @ts-expect-error
  static getDerivedStateFromProps(props, state) {
    const isValid = props.onValidate(props.value)
    return isValid !== state.isValid ? {isValid} : null
  }

  // @ts-expect-error
  handleDateChange = value => {
    // @ts-expect-error
    const isValid = this.props.onValidate(value)
    this.setState({isValid}, () => {
      if (!isValid) {
        showFlashAlert({
          // @ts-expect-error
          message: this.props.invalidMessage() || fallbackErrorMessage,
          type: 'error',
          srOnly: true,
        })
      }
      // @ts-expect-error
      this.props.onChange(value)
    })
  }

  // @ts-expect-error
  invalidDateTimeMessage = (rawDateValue, rawTimeValue) => {
    // @ts-expect-error
    this.props.onValidate({rawDateValue, rawTimeValue})
    // @ts-expect-error
    const message = this.props.invalidMessage() || fallbackErrorMessage
    this.setState({isValid: false})
    showFlashAlert({
      message,
      type: 'error',
      srOnly: true,
    })
    return message
  }

  getMessages = () =>
    // @ts-expect-error
    this.state.isValid
      ? null
      : // @ts-expect-error
        [{type: 'error', text: this.props.invalidMessage() || fallbackErrorMessage}]

  render() {
    // @ts-expect-error
    const lbl = I18n.t('%{label}:', {label: this.props.label})
    // @ts-expect-error
    const placeholder = I18n.t('No %{label} Date', {label: this.props.label})
    const messages = this.getMessages()
    // can remove the outer DIV once instui is updated
    // to forward data-* attrs from FormField into the dom
    return (
      <div data-testid="AssignmentDate">
        {/* @ts-expect-error */}
        <FormField id={this.id} label={lbl} layout="stacked">
          <EditableDateTime
            // @ts-expect-error
            mode={this.props.mode}
            onChange={this.handleDateChange}
            // @ts-expect-error
            onChangeMode={this.props.onChangeMode}
            invalidMessage={this.invalidDateTimeMessage}
            messages={messages}
            // @ts-expect-error
            value={this.props.value || undefined}
            // @ts-expect-error
            label={this.props.label}
            // @ts-expect-error
            locale={this.context.locale}
            // @ts-expect-error
            timeZone={this.context.timeZone}
            // @ts-expect-error
            readOnly={this.props.readOnly}
            placeholder={placeholder}
          />
        </FormField>
      </div>
    )
  }
}
