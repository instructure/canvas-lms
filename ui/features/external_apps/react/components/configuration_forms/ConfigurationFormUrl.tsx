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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import {TextInput} from '@instructure/ui-text-input'
import type {FormMessage} from '@instructure/ui-form-field'
// Misconfigured types in Grid's package.json mean we have to ignore errors here
import {Grid} from '@instructure/ui-grid'
import '@canvas/rails-flash-notifications'
import type {I18nType, TextInputChangeHandler} from './types'
import MembershipServiceAccess from './MembershipServiceAccess'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const I18n: I18nType = useI18nScope('external_tools')

export interface ConfigurationFormUrlProps {
  name?: string
  consumerKey?: string
  sharedSecret?: string
  configUrl?: string
  allowMembershipServiceAccess?: boolean
  membershipServiceFeatureFlagEnabled: boolean
}

interface ConfigurationFormUrlErrors {
  name?: FormMessage[]
  configUrl?: FormMessage[]
}

export interface ConfigurationFormUrlState {
  name: string
  consumerKey: string
  sharedSecret: string
  configUrl: string
  allowMembershipServiceAccess: boolean
  errors: ConfigurationFormUrlErrors
}

export interface ConfigurationFormUrlFormData
  extends Omit<ConfigurationFormUrlState, 'errors' | 'allowMembershipServiceAccess'> {
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
    errors: {},
  }

  isValid = () => {
    const fields: (keyof ConfigurationFormUrlState & keyof ConfigurationFormUrlErrors)[] = [
        'name',
        'configUrl',
      ],
      errors: ConfigurationFormUrlErrors = {},
      formErrors: string[] = []

    fields.forEach(field => {
      const value = this.state[field]
      if (!value) {
        errors[field] = [{text: I18n.t('This field is required'), type: 'error'}]
        formErrors.push(I18n.t('This field "%{name}" is required.', {name: field}))
      }
    })
    this.setState({errors})

    let isValid = true
    if (formErrors.length > 0) {
      isValid = false
      showFlashAlert({
        message: I18n.t('There were errors with the form: %{errors}', {
          errors: formErrors.join(' '),
        }),
        type: 'error',
        politeness: 'assertive',
      })
    }
    return isValid
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
      this.setState(prevState => ({...prevState, [field]: value}))
    }
  }

  render() {
    return (
      <div className="ConfigurationFormUrl">
        <Grid hAlign="space-between" colSpacing="none" rowSpacing="small">
          <Grid.Row>
            <Grid.Col>
              <TextInput
                id="name"
                value={this.state.name}
                onChange={this.handleChange('name')}
                renderLabel={I18n.t('Name')}
                isRequired={true}
                messages={this.state.errors.name}
              />
            </Grid.Col>
          </Grid.Row>
          <Grid.Row colSpacing="small" startAt="medium">
            <Grid.Col>
              <TextInput
                id="consumerKey"
                value={this.state.consumerKey}
                onChange={this.handleChange('consumerKey')}
                renderLabel={I18n.t('Consumer Key')}
              />
            </Grid.Col>
            <Grid.Col>
              <TextInput
                id="sharedSecret"
                value={this.state.sharedSecret}
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
                value={this.state.configUrl}
                onChange={this.handleChange('configUrl')}
                renderLabel={I18n.t('Config URL')}
                placeholder={I18n.t('https://example.com/config.xml')}
                isRequired={true}
                messages={this.state.errors.configUrl}
              />
            </Grid.Col>
          </Grid.Row>
        </Grid>
      </div>
    )
  }
}
