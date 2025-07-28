/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import React, {createRef} from 'react'
import {TextInput} from '@instructure/ui-text-input'
import type {FormMessage} from '@instructure/ui-form-field'
// Misconfigured types in Grid's package.json mean we have to ignore errors here
import {Grid} from '@instructure/ui-grid'
import '@canvas/rails-flash-notifications'
import type {I18nType, TextInputChangeHandler} from './types'
import MembershipServiceAccess from './MembershipServiceAccess'

const I18n: I18nType = createI18nScope('external_tools')

export interface ConfigurationFormUrlProps {
  name?: string
  consumerKey?: string
  sharedSecret?: string
  configUrl?: string
  allowMembershipServiceAccess?: boolean
  membershipServiceFeatureFlagEnabled: boolean
}

interface ConfigurationFormUrlErrors {
  missing?: FormMessage[]
  invalidUrl?: FormMessage[]
}

export interface ConfigurationFormUrlState {
  name: string
  consumerKey: string
  sharedSecret: string
  configUrl: string
  allowMembershipServiceAccess: boolean
  showMessages: boolean
  isNameValid: boolean
  isConfigUrlValid: boolean
}

export interface ConfigurationFormUrlFormData
  extends Omit<
    ConfigurationFormUrlState,
    'allowMembershipServiceAccess' | 'isNameValid' | 'isConfigUrlValid' | 'showMessages'
  > {
  name: string
  consumerKey: string
  sharedSecret: string
  configUrl: string
  allow_membership_service_access?: boolean
  verifyUniqueness: 'true'
}

export default class ConfigurationFormUrl extends React.Component<
  ConfigurationFormUrlProps,
  ConfigurationFormUrlState
> {
  state: ConfigurationFormUrlState = {
    name: this.props.name ?? '',
    consumerKey: this.props.consumerKey ?? '',
    sharedSecret: this.props.sharedSecret ?? '',
    configUrl: this.props.configUrl ?? '',
    allowMembershipServiceAccess: this.props.allowMembershipServiceAccess ?? false,
    showMessages: false,
    isNameValid: true,
    isConfigUrlValid: true,
  }

  nameRef = createRef<TextInput>()
  configUrlRef = createRef<TextInput>()

  errors: ConfigurationFormUrlErrors = {
    missing: [{text: I18n.t('This field is required'), type: 'error'}],
    invalidUrl: [
      {text: I18n.t('Please enter a valid URL (e.g. https://example.com)'), type: 'error'},
    ],
  }

  valid = true

  validateField = (
    fieldValue: string,
    fieldStateKey: 'isNameValid' | 'isConfigUrlValid',
    fieldRef: React.RefObject<TextInput>,
    isUrl: boolean,
  ) => {
    if (!fieldValue || (isUrl && !URL.canParse(fieldValue))) {
      this.invalidate(fieldStateKey, fieldRef)
    } else {
      this.setState(prevState => ({...prevState, [fieldStateKey]: true}))
    }
  }

  invalidate = (
    fieldStateKey: 'isNameValid' | 'isConfigUrlValid',
    fieldRef: React.RefObject<TextInput>,
  ) => {
    this.setState(prevState => ({...prevState, [fieldStateKey]: false}))
    if (this.valid) {
      fieldRef.current?.focus()
      this.valid = false
      this.setState({showMessages: true})
    }
  }

  isValid = () => {
    this.valid = true

    const name = this.state.name,
      configUrl = this.state.configUrl

    this.validateField(name, 'isNameValid', this.nameRef, false)
    this.validateField(configUrl, 'isConfigUrlValid', this.configUrlRef, true)

    return this.valid
  }

  getFormData = (): ConfigurationFormUrlFormData => {
    const data: ConfigurationFormUrlFormData = {
      name: this.state.name,
      consumerKey: this.state.consumerKey,
      sharedSecret: this.state.sharedSecret,
      configUrl: this.state.configUrl,
      verifyUniqueness: 'true',
    }

    if (this.props.membershipServiceFeatureFlagEnabled) {
      data.allow_membership_service_access = this.state.allowMembershipServiceAccess
    }

    return data
  }

  handleChange: (field: keyof ConfigurationFormUrlState) => TextInputChangeHandler = field => {
    return (_, value) => {
      if (field === 'name') {
        this.validateField(value, 'isNameValid', this.nameRef, false)
      }
      if (field === 'configUrl') {
        this.validateField(value, 'isConfigUrlValid', this.configUrlRef, true)
      }
      this.setState(prevState => ({...prevState, [field]: value}))
    }
  }

  render() {
    const {
      name,
      isNameValid,
      isConfigUrlValid,
      consumerKey,
      sharedSecret,
      configUrl,
      showMessages,
    } = this.state

    return (
      <div className="ConfigurationFormUrl">
        <Grid hAlign="space-between" colSpacing="none" rowSpacing="small">
          <Grid.Row>
            <Grid.Col>
              <TextInput
                id="name"
                value={name}
                onChange={this.handleChange('name')}
                renderLabel={I18n.t('Name')}
                ref={this.nameRef}
                isRequired
                messages={showMessages && !isNameValid ? this.errors.missing : []}
              />
            </Grid.Col>
          </Grid.Row>
          <Grid.Row colSpacing="small" startAt="medium">
            <Grid.Col>
              <TextInput
                id="consumerKey"
                value={consumerKey}
                onChange={this.handleChange('consumerKey')}
                renderLabel={I18n.t('Consumer Key')}
              />
            </Grid.Col>
            <Grid.Col>
              <TextInput
                id="sharedSecret"
                value={sharedSecret}
                onChange={this.handleChange('sharedSecret')}
                renderLabel={I18n.t('Shared Secret')}
              />
            </Grid.Col>
          </Grid.Row>

          <Grid.Row>
            <Grid.Col>
              <MembershipServiceAccess
                membershipServiceFeatureFlagEnabled={this.props.membershipServiceFeatureFlagEnabled}
                checked={this.state.allowMembershipServiceAccess}
                onChange={() =>
                  this.setState(prevState => ({
                    allowMembershipServiceAccess: !prevState.allowMembershipServiceAccess,
                  }))
                }
              />
            </Grid.Col>
          </Grid.Row>

          <Grid.Row>
            <Grid.Col>
              <TextInput
                id="configUrl"
                value={configUrl}
                onChange={this.handleChange('configUrl')}
                renderLabel={I18n.t('Config URL')}
                placeholder={I18n.t('https://example.com/config.xml')}
                ref={this.configUrlRef}
                isRequired
                messages={showMessages && !isConfigUrlValid ? this.errors.invalidUrl : []}
              />
            </Grid.Col>
          </Grid.Row>
        </Grid>
      </div>
    )
  }
}
