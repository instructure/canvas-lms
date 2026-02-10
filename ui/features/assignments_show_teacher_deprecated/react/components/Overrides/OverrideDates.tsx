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
import {Flex} from '@instructure/ui-flex'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

import AssignmentDate from '../Editables/AssignmentDate'

const I18n = createI18nScope('assignments_2')

export default class OverrideDates extends React.Component {
  static propTypes = {
    mode: oneOf(['view', 'edit']), // TODO: needs to be isReqired from above
    onChange: func.isRequired,
    onValidate: func.isRequired,
    invalidMessage: func.isRequired,
    dueAt: string,
    unlockAt: string,
    lockAt: string,
    readOnly: bool,
  }

  static defaultProps = {
    readOnly: false,
  }

  // @ts-expect-error
  constructor(props) {
    super(props)

    const mode = props.mode || 'view'
    this.state = {
      dueMode: mode,
      unlockMode: mode,
      lockMode: mode,
    }
  }

  // @ts-expect-error
  onChangeDue = newValue => this.props.onChange('dueAt', newValue)

  // @ts-expect-error
  onChangeUnlock = newValue => this.props.onChange('unlockAt', newValue)

  // @ts-expect-error
  onChangeLock = newValue => this.props.onChange('lockAt', newValue)

  // @ts-expect-error
  onChangeDueMode = dueMode => this.setState({dueMode})

  // @ts-expect-error
  onChangeUnlockMode = unlockMode => this.setState({unlockMode})

  // @ts-expect-error
  onChangeLockMode = lockMode => this.setState({lockMode})

  // @ts-expect-error
  onValidateDue = value => this.props.onValidate('dueAt', value)

  // @ts-expect-error
  onValidateUnlock = value => this.props.onValidate('unlockAt', value)

  // @ts-expect-error
  onValidateLock = value => this.props.onValidate('lockAt', value)

  // @ts-expect-error
  invalidMessageDue = () => this.props.invalidMessage('dueAt')

  // @ts-expect-error
  invalidMessageUnlock = () => this.props.invalidMessage('unlockAt')

  // @ts-expect-error
  invalidMessageLock = () => this.props.invalidMessage('lockAt')

  allDatesAreBeingViewed = () =>
    // @ts-expect-error
    this.state.dueMode === 'view' &&
    // @ts-expect-error
    this.state.unlockMode === 'view' &&
    // @ts-expect-error
    this.state.lockMode === 'view'

  // @ts-expect-error
  renderDate(field, label, value, mode, onchange, onchangemode, onvalidate, invalidMessage) {
    return (
      <AssignmentDate
        mode={mode}
        onChange={onchange}
        onChangeMode={onchangemode}
        onValidate={onvalidate}
        invalidMessage={invalidMessage}
        // @ts-expect-error
        field={field}
        value={value}
        label={label}
        // @ts-expect-error
        readOnly={this.props.readOnly}
      />
    )
  }

  render() {
    // show an error message only when all dates are in view
    const message =
      this.allDatesAreBeingViewed() &&
      (this.invalidMessageDue() || this.invalidMessageUnlock() || this.invalidMessageLock())
    return (
      <FormFieldGroup
        description={
          <ScreenReaderContent>{I18n.t('Due, available, and until dates')}</ScreenReaderContent>
        }
        // @ts-expect-error
        messages={message ? [{type: 'error', text: message}] : null}
      >
        <Flex
          as="div"
          margin="small 0"
          padding="0"
          justifyItems="space-between"
          alignItems="start"
          wrap="wrap"
          data-testid="OverrideDates"
        >
          <Flex.Item margin="0 x-small 0 0" as="div" shouldGrow={true} width="30%">
            {this.renderDate(
              'due_at',
              I18n.t('Due'),
              // @ts-expect-error
              this.props.dueAt,
              // @ts-expect-error
              this.state.dueMode,
              this.onChangeDue,
              this.onChangeDueMode,
              this.onValidateDue,
              this.invalidMessageDue,
            )}
          </Flex.Item>
          <Flex.Item margin="0 x-small 0 0" as="div" shouldGrow={true} width="30%">
            {this.renderDate(
              'unlock_at',
              I18n.t('Available'),
              // @ts-expect-error
              this.props.unlockAt,
              // @ts-expect-error
              this.state.unlockMode,
              this.onChangeUnlock,
              this.onChangeUnlockMode,
              this.onValidateUnlock,
              this.invalidMessageUnlock,
            )}
          </Flex.Item>
          <Flex.Item margin="0 0 0 0" as="div" shouldGrow={true} width="30%">
            {this.renderDate(
              'lock_at',
              I18n.t('Until'),
              // @ts-expect-error
              this.props.lockAt,
              // @ts-expect-error
              this.state.lockMode,
              this.onChangeLock,
              this.onChangeLockMode,
              this.onValidateLock,
              this.invalidMessageLock,
            )}
          </Flex.Item>
        </Flex>
      </FormFieldGroup>
    )
  }
}
