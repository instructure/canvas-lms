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

import I18n from 'i18n!react_developer_keys'
import PropTypes from 'prop-types'
import React from 'react'
import RadioInputGroup from '@instructure/ui-forms/lib/components/RadioInputGroup'
import RadioInput from '@instructure/ui-forms/lib/components/RadioInput'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'

export default class DeveloperKeyStateControl extends React.Component {
  setBindingState = newValue => {
    this.props.store.dispatch(
      this.props.actions.setBindingWorkflowState(
        this.props.developerKey.id,
        this.props.ctx.params.contextId,
        newValue
      )
    )
  }

  disabled() {
    if (this.radioGroupValue() === 'allow') {
      return false
    }
    return !this.props.developerKey.developer_key_account_binding.account_owns_binding
  }

  isDisabled = () => {
    const devKeyBinding = this.props.developerKey.developer_key_account_binding
    if (!devKeyBinding || devKeyBinding.workflow_state === 'allow') { return false }
    return !devKeyBinding.account_owns_binding
  }

  radioGroupValue() {
    const devKeyBinding = this.props.developerKey.developer_key_account_binding
    if (devKeyBinding) {
      return devKeyBinding.workflow_state || 'allow'
    }
    return 'allow'
  }

  isSiteAdmin() {
    return this.props.ctx.params.contextId === "site_admin"
  }

  getDefaultValue() {
    return this.radioGroupValue() === 'allow' && !this.isSiteAdmin() ? 'off' : this.radioGroupValue()
  }

  focusToggleGroup = () => {
    this[`${this.getDefaultValue()}Toggle`].focus()
  }

  refOnToggle = (node) => { this.onToggle = node }
  refOffToggle = (node) => { this.offToggle = node }

  render() {
    return (
      <RadioInputGroup
        size="medium"
        variant="toggle"
        defaultValue={this.getDefaultValue()}
        description={
          <ScreenReaderContent>{I18n.t('Key state for the current account')}</ScreenReaderContent>
        }
        onChange={(e, val) => this.setBindingState(val)}
        disabled={this.disabled()}
        name={this.props.developerKey.id}
      >
        <RadioInput ref={this.refOnToggle} label={I18n.t('On')} value="on" context="success" />
        {this.isSiteAdmin() && <RadioInput ref={(node) => {this.allowToggle = node}} label={I18n.t('Allow')} value="allow" context="off"/>}
        <RadioInput ref={this.refOffToggle} label={I18n.t('Off')} value="off" context="danger" />
      </RadioInputGroup>
    )
  }
}

DeveloperKeyStateControl.propTypes = {
  store: PropTypes.shape({
    dispatch: PropTypes.func.isRequired
  }).isRequired,
  actions: PropTypes.shape({
    setBindingWorkflowState: PropTypes.func.isRequired
  }).isRequired,
  developerKey: PropTypes.shape({
    id: PropTypes.string.isRequired,
    workflow_state: PropTypes.string,
    developer_key_account_binding: PropTypes.shape({
      workflow_state: PropTypes.string.isRequired,
      account_owns_binding: PropTypes.bool
    }),
  }),
  ctx: PropTypes.shape({
    params: PropTypes.shape({
      contextId: PropTypes.string.isRequired
    })
  }).isRequired
}

DeveloperKeyStateControl.defaultProps = {
  developerKey: {}
}
