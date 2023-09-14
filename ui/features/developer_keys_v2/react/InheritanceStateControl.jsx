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

import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React from 'react'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {Checkbox} from '@instructure/ui-checkbox'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = useI18nScope('react_developer_keys')

export default class DeveloperKeyStateControl extends React.Component {
  setBindingState = newValue => {
    // eslint-disable-next-line no-alert
    const confirmation = window.confirm(
      I18n.t('Are you sure you want to change the state of this developer key?')
    )
    if (!confirmation) {
      return
    }
    this.props.store.dispatch(
      this.props.actions.setBindingWorkflowState(
        this.props.developerKey,
        this.props.ctx.params.contextId,
        newValue
      )
    )
  }

  isDisabled() {
    if (this.props.developerKey.inherited_to === 'child_account') {
      return true
    }
    const devKeyBinding = this.props.developerKey.developer_key_account_binding
    if (!devKeyBinding || this.radioGroupValue() === 'allow') {
      return false
    }
    return !this.props.developerKey.developer_key_account_binding.account_owns_binding
  }

  radioGroupValue() {
    const devKeyBinding = this.props.developerKey.developer_key_account_binding
    if (devKeyBinding) {
      return devKeyBinding.workflow_state || 'allow'
    } else if (!this.isSiteAdmin()) {
      return 'off'
    } else {
      return 'allow'
    }
  }

  isSiteAdmin() {
    return this.props.ctx.params.contextId === 'site_admin'
  }

  getDefaultValue() {
    return this.radioGroupValue() === 'allow' && !this.isSiteAdmin()
      ? 'off'
      : this.radioGroupValue()
  }

  focusToggleGroup = () => {
    this[`${this.getDefaultValue()}Toggle`].focus()
  }

  refOnToggle = node => {
    this.onToggle = node
  }

  refOffToggle = node => {
    this.offToggle = node
  }

  refCheckboxToggle = node => {
    // Only onToggle and offToggle are set, since a checkbox should only
    // be used for non-siteadmin keys, so the allowToggle function *shouldn't*
    // ever get called.
    this.onToggle = node
    this.offToggle = node
  }

  getKeyName() {
    return this.props.developerKey.name || I18n.t('Unnamed Key')
  }

  render() {
    if (this.isSiteAdmin()) {
      return (
        <RadioInputGroup
          size="medium"
          variant="toggle"
          defaultValue={this.getDefaultValue()}
          description={
            <ScreenReaderContent>{I18n.t('Key state for the current account')}</ScreenReaderContent>
          }
          onChange={(e, val) => this.setBindingState(val)}
          disabled={this.isDisabled()}
          name={this.props.developerKey.id}
          value={this.radioGroupValue()}
        >
          <RadioInput
            ref={this.refOnToggle}
            label={
              <div>
                {I18n.t('On')}
                <ScreenReaderContent>
                  {I18n.t('On for key: %{keyName}', {keyName: this.getKeyName()})}
                </ScreenReaderContent>
              </div>
            }
            value="on"
            context="success"
          />
          {this.isSiteAdmin() && (
            <RadioInput
              ref={node => {
                this.allowToggle = node
              }}
              label={
                <div>
                  {I18n.t('Allow')}
                  <ScreenReaderContent>
                    {I18n.t('Allow for key: %{keyName}', {keyName: this.getKeyName()})}
                  </ScreenReaderContent>
                </div>
              }
              value="allow"
              context="off"
            />
          )}
          <RadioInput
            ref={this.refOffToggle}
            label={
              <div>
                {I18n.t('Off')}
                <ScreenReaderContent>
                  {I18n.t('Off for key: %{keyName}', {keyName: this.getKeyName()})}
                </ScreenReaderContent>
              </div>
            }
            value="off"
            context="danger"
          />
        </RadioInputGroup>
      )
    } else {
      return (
        <Checkbox
          ref={this.refCheckboxToggle}
          label={
            <ScreenReaderContent>
              {I18n.t('%{status} for key: %{keyName}', {
                status: this.radioGroupValue(),
                keyName: this.getKeyName(),
              })}
            </ScreenReaderContent>
          }
          variant="toggle"
          checked={this.radioGroupValue() === 'on'}
          disabled={this.isDisabled()}
          name={this.props.developerKey.id}
          onChange={e => {
            const newValue = e.target.checked ? 'on' : 'off'
            this.setBindingState(newValue)
          }}
        />
      )
    }
  }
}

DeveloperKeyStateControl.propTypes = {
  store: PropTypes.shape({
    dispatch: PropTypes.func.isRequired,
  }).isRequired,
  actions: PropTypes.shape({
    setBindingWorkflowState: PropTypes.func.isRequired,
  }).isRequired,
  developerKey: PropTypes.shape({
    id: PropTypes.string.isRequired,
    inherited_to: PropTypes.string,
    workflow_state: PropTypes.string,
    name: PropTypes.string,
    developer_key_account_binding: PropTypes.shape({
      workflow_state: PropTypes.string.isRequired,
      account_owns_binding: PropTypes.bool,
    }),
  }),
  ctx: PropTypes.shape({
    params: PropTypes.shape({
      contextId: PropTypes.string.isRequired,
    }),
  }).isRequired,
}

DeveloperKeyStateControl.defaultProps = {
  developerKey: {},
}
