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
import {SimpleSelect} from '@instructure/ui-simple-select'
// ui-text-area has types in InstUI 7, but they aren't declared in its package.json
// so just ignore the error for now. Once we're on InstUI 8, we can remove this.
import {TextArea} from '@instructure/ui-text-area'
// ui-grid has types in InstUI 7, but they aren't declared in its package.json
// so just ignore the error for now. Once we're on InstUI 8, we can remove this.
import {Grid} from '@instructure/ui-grid'
import '@canvas/rails-flash-notifications'
import type {I18nType, TextAreaChangeHandler, TextInputChangeHandler} from './types'
import MembershipServiceAccess from './MembershipServiceAccess'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
// Doing this to avoid TS2339 errors-- remove once we're on InstUI 8
const {Option: SimpleSelectOption} = SimpleSelect as any

const I18n: I18nType = useI18nScope('external_tools')

const PRIVACY_OPTIONS = {
  anonymous: I18n.t('Anonymous'),
  email_only: I18n.t('E-Mail Only'),
  name_only: I18n.t('Name Only'),
  public: I18n.t('Public'),
}

export interface ConfigurationFormManualProps {
  name?: string
  consumerKey?: string
  sharedSecret?: string
  url?: string
  domain?: string
  privacyLevel?: keyof typeof PRIVACY_OPTIONS
  customFields?: Record<string, string>
  description?: string
  allowMembershipServiceAccess?: boolean
  membershipServiceFeatureFlagEnabled: boolean
}

interface ConfigurationFormManualErrors {
  name?: FormMessage[]
  url?: FormMessage[]
  domain?: FormMessage[]
}

export interface ConfigurationFormManualState {
  name: string
  consumerKey: string
  sharedSecret: string
  url: string
  domain: string
  privacyLevel: keyof typeof PRIVACY_OPTIONS
  customFields: string
  description: string
  allowMembershipServiceAccess: boolean
  errors: ConfigurationFormManualErrors
}

export interface ConfigurationFormManualFormData
  extends Omit<ConfigurationFormManualState, 'allowMembershipServiceAccess' | 'errors'> {
  allow_membership_service_access?: boolean
  verifyUniqueness: 'true'
}

export default class ConfigurationFormManual extends React.Component<
  ConfigurationFormManualProps,
  ConfigurationFormManualState
> {
  state: ConfigurationFormManualState = {
    name: this.props.name ?? '',
    consumerKey: this.props.consumerKey ?? '',
    sharedSecret: this.props.sharedSecret ?? '',
    url: this.props.url ?? '',
    domain: this.props.domain ?? '',
    privacyLevel: this.props.privacyLevel ?? 'anonymous',
    customFields: ConfigurationFormManual.customFieldsToMultiLine(this.props.customFields) ?? '',
    description: this.props.description ?? '',
    allowMembershipServiceAccess: this.props.allowMembershipServiceAccess ?? false,
    errors: {},
  }

  isValid = () => {
    const errors: ConfigurationFormManualErrors = {},
      formErrors = [],
      name = this.state.name,
      url = this.state.url,
      domain = this.state.domain

    if (name.length === 0) {
      errors.name = [{text: I18n.t('This field is required'), type: 'error'}]
      formErrors.push(I18n.t('This field "name" is required.'))
    }

    if (url.length === 0 && domain.length === 0) {
      errors.url = [{text: I18n.t('Either the url or domain should be set.'), type: 'error'}]
      errors.domain = [{text: I18n.t('Either the url or domain should be set.'), type: 'error'}]
      formErrors.push(I18n.t('Either the url or domain should be set.'))
    }

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

  getFormData = (): ConfigurationFormManualFormData => {
    const data: ConfigurationFormManualFormData = {
      name: this.state.name,
      consumerKey: this.state.consumerKey,
      sharedSecret: this.state.sharedSecret,
      url: this.state.url,
      domain: this.state.domain,
      privacyLevel: this.state.privacyLevel,
      customFields: this.state.customFields,
      description: this.state.description,
      verifyUniqueness: 'true',
    }

    if (this.props.membershipServiceFeatureFlagEnabled) {
      data.allow_membership_service_access = this.state.allowMembershipServiceAccess
    }

    return data
  }

  static customFieldsToMultiLine = (customFields: Record<string, string> | undefined) => {
    if (!customFields) {
      return ''
    }

    return Object.entries(customFields)
      .map(([key, value]) => `${key}=${value}`)
      .join('\n')
  }

  handleFieldChange: (
    field: Exclude<keyof ConfigurationFormManualState, 'description' | 'customFields'>
  ) => TextInputChangeHandler = field => {
    return (_, value) => {
      this.setState(prevState => ({...prevState, [field]: value}))
    }
  }

  handlePrivacyChange: (
    event: React.SyntheticEvent,
    data: {value?: string | number; id?: string}
  ) => void = (_, data) => {
    this.setState({privacyLevel: data.value as keyof typeof PRIVACY_OPTIONS})
  }

  handleCustomFieldsChange: TextAreaChangeHandler = e => {
    this.setState({customFields: e.target.value})
  }

  handleDescriptionChange: TextAreaChangeHandler = e => {
    this.setState({description: e.target.value})
  }

  render() {
    return (
      <div className="ConfigurationFormManual">
        <Grid hAlign="space-between" colSpacing="none" rowSpacing="small">
          <Grid.Row>
            <Grid.Col>
              <TextInput
                id="name"
                value={this.state.name}
                onChange={this.handleFieldChange('name')}
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
                onChange={this.handleFieldChange('consumerKey')}
                renderLabel={I18n.t('Consumer Key')}
              />
            </Grid.Col>

            <Grid.Col>
              <TextInput
                id="sharedSecret"
                value={this.state.sharedSecret}
                onChange={this.handleFieldChange('sharedSecret')}
                placeholder={this.props.consumerKey ? I18n.t('[Unchanged]') : undefined} // Assume that if we have a consumer key, we have a secret
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
                id="url"
                onChange={this.handleFieldChange('url')}
                value={this.state.url}
                renderLabel={I18n.t('Launch URL')}
                isRequired={true}
                messages={this.state.errors.url}
              />
            </Grid.Col>
          </Grid.Row>

          <Grid.Row colSpacing="small" startAt="medium">
            <Grid.Col>
              <TextInput
                id="domain"
                value={this.state.domain}
                onChange={this.handleFieldChange('domain')}
                renderLabel={I18n.t('Domain')}
                messages={this.state.errors.domain}
              />
            </Grid.Col>

            <Grid.Col>
              <SimpleSelect
                id="privacyLevel"
                value={this.state.privacyLevel}
                onChange={this.handlePrivacyChange}
                renderLabel={I18n.t('Privacy Level')}
              >
                {Object.entries(PRIVACY_OPTIONS).map(([value, translated]) => (
                  <SimpleSelectOption
                    key={value}
                    id={value}
                    value={value}
                    selected={value === this.state.privacyLevel}
                  >
                    {translated}
                  </SimpleSelectOption>
                ))}
              </SimpleSelect>
            </Grid.Col>
          </Grid.Row>

          <Grid.Row>
            <Grid.Col>
              <TextArea
                id="customFields"
                value={this.state.customFields}
                onChange={this.handleCustomFieldsChange}
                label={I18n.t('Custom Fields')}
                placeholder={I18n.t('One per line. Format: name=value')}
                resize="vertical"
                height="6rem"
              />
            </Grid.Col>
          </Grid.Row>
          <Grid.Row>
            <Grid.Col>
              <TextArea
                id="description"
                value={this.state.description}
                onChange={this.handleDescriptionChange}
                label={I18n.t('Description')}
                height="6rem"
                resize="vertical"
              />
            </Grid.Col>
          </Grid.Row>
        </Grid>
      </div>
    )
  }
}
