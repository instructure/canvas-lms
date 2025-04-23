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
import {SimpleSelect} from '@instructure/ui-simple-select'
import {TextArea} from '@instructure/ui-text-area'
import {Grid} from '@instructure/ui-grid'
import '@canvas/rails-flash-notifications'
import type {I18nType, TextAreaChangeHandler, TextInputChangeHandler} from './types'
import MembershipServiceAccess from './MembershipServiceAccess'

const I18n: I18nType = createI18nScope('external_tools')

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
  hasBeenSubmitted?: boolean
}

interface ConfigurationFormManualErrors {
  missing?: FormMessage[]
  urlOrDomain?: FormMessage[]
  invalidUrl?: FormMessage[]
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
  showMessages: boolean
  isNameValid: boolean
  isUrlValid: boolean
  isDomainValid: boolean
  isUrlRequired: boolean
}

export interface ConfigurationFormManualFormData
  extends Omit<
    ConfigurationFormManualState,
    | 'allowMembershipServiceAccess'
    | 'isNameValid'
    | 'isUrlValid'
    | 'isDomainValid'
    | 'showMessages'
    | 'isUrlRequired'
  > {
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
    showMessages: false,
    isNameValid: true,
    isUrlValid: true,
    isDomainValid: true,
    isUrlRequired: true,
  }

  nameRef = createRef<TextInput>()
  urlRef = createRef<TextInput>()
  domainRef = createRef<TextInput>()

  valid = true

  errors: ConfigurationFormManualErrors = {
    missing: [{text: I18n.t('This field is required'), type: 'error'}],
    urlOrDomain: [
      {text: I18n.t('One or both of Launch URL and Domain should be entered.'), type: 'error'},
    ],
    invalidUrl: [
      {text: I18n.t('Please enter a valid URL (e.g. https://example.com)'), type: 'error'},
    ],
  }

  validateField = (
    fieldValue: string,
    fieldStateKey: 'isNameValid' | 'isUrlValid' | 'isDomainValid',
    fieldRef: React.RefObject<TextInput>,
    isUrl: boolean,
  ) => {
    if (fieldStateKey === 'isDomainValid' && this.state.isUrlValid) {
      this.setState(prevState => ({...prevState, [fieldStateKey]: true}))
      return
    }
    if (!fieldValue || (isUrl && !URL.canParse(fieldValue))) {
      this.invalidate(fieldStateKey, fieldRef)
      return
    }

    this.setState(prevState => ({...prevState, [fieldStateKey]: true}))
  }

  invalidate = (
    fieldStateKey: 'isNameValid' | 'isUrlValid' | 'isDomainValid',
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

    const {name, url, domain} = this.state

    this.validateField(name, 'isNameValid', this.nameRef, false)
    if (this.state.isUrlRequired || url.length > 0) {
      this.validateField(url, 'isUrlValid', this.urlRef, true)
    }
    if (!url) {
      this.validateField(domain, 'isDomainValid', this.domainRef, false)
    }

    if (url.length === 0 && domain.length === 0) {
      this.valid = false
      this.setState({showMessages: true})
    }

    return this.valid
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
    field: Exclude<keyof ConfigurationFormManualState, 'description' | 'customFields'>,
  ) => TextInputChangeHandler = field => {
    return (e, value) => {
      const fieldId = e.target.id

      this.setState(prevState => ({...prevState, [field]: value}))

      switch (fieldId) {
        case 'name':
          this.validateField(value, 'isNameValid', this.nameRef, false)
          break
        case 'url':
          this.validateField(value, 'isUrlValid', this.urlRef, true)
          break
        case 'domain':
          if (value !== '') this.setState({isUrlRequired: false})
          this.validateField(value, 'isDomainValid', this.domainRef, false)
          break
      }
    }
  }

  handlePrivacyChange: (
    event: React.SyntheticEvent,
    data: {value?: string | number; id?: string},
  ) => void = (_, data) => {
    this.setState({privacyLevel: data.value as keyof typeof PRIVACY_OPTIONS})
  }

  handleCustomFieldsChange: TextAreaChangeHandler = e => {
    this.setState({customFields: e.target.value})
  }

  handleDescriptionChange: TextAreaChangeHandler = e => {
    this.setState({description: e.target.value})
  }

  showUrlValidationError = (domain: string) => {
    if (domain && !this.state.url) {
      return []
    }
    if (!this.state.isUrlValid) {
      return this.errors.invalidUrl
    }
    if (!this.state.domain && !this.state.url) {
      return this.errors.urlOrDomain
    }
    return []
  }

  showDomainValidationError = (url: string, domain: string) => {
    return !url && !domain ? this.errors.urlOrDomain : []
  }

  render() {
    const {
      name,
      consumerKey,
      sharedSecret,
      url,
      domain,
      privacyLevel,
      customFields,
      description,
      showMessages,
      isUrlRequired,
      isNameValid,
    } = this.state

    return (
      <div className="ConfigurationFormManual">
        <Grid hAlign="space-between" colSpacing="none" rowSpacing="small">
          <Grid.Row>
            <Grid.Col>
              <TextInput
                id="name"
                value={name}
                onChange={this.handleFieldChange('name')}
                renderLabel={I18n.t('Name')}
                ref={this.nameRef}
                isRequired
                messages={
                  this.props.hasBeenSubmitted && showMessages && !isNameValid
                    ? this.errors.missing
                    : []
                }
              />
            </Grid.Col>
          </Grid.Row>
          <Grid.Row colSpacing="small" startAt="medium">
            <Grid.Col>
              <TextInput
                id="consumerKey"
                value={consumerKey}
                onChange={this.handleFieldChange('consumerKey')}
                renderLabel={I18n.t('Consumer Key')}
              />
            </Grid.Col>

            <Grid.Col>
              <TextInput
                id="sharedSecret"
                value={sharedSecret}
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
                value={url}
                renderLabel={I18n.t('Launch URL')}
                ref={this.urlRef}
                isRequired={isUrlRequired}
                messages={
                  this.props.hasBeenSubmitted && showMessages
                    ? this.showUrlValidationError(domain)
                    : []
                }
              />
            </Grid.Col>
          </Grid.Row>

          <Grid.Row colSpacing="small" startAt="medium">
            <Grid.Col>
              <TextInput
                id="domain"
                value={domain}
                onChange={this.handleFieldChange('domain')}
                renderLabel={I18n.t('Domain')}
                ref={this.domainRef}
                messages={
                  this.props.hasBeenSubmitted && showMessages
                    ? this.showDomainValidationError(url, domain)
                    : []
                }
              />
            </Grid.Col>

            <Grid.Col>
              <SimpleSelect
                id="privacyLevel"
                value={privacyLevel}
                onChange={this.handlePrivacyChange}
                renderLabel={I18n.t('Privacy Level')}
              >
                {Object.entries(PRIVACY_OPTIONS).map(([value, translated]) => (
                  <SimpleSelect.Option
                    key={value}
                    id={value}
                    value={value}
                    selected={value === privacyLevel}
                  >
                    {translated}
                  </SimpleSelect.Option>
                ))}
              </SimpleSelect>
            </Grid.Col>
          </Grid.Row>

          <Grid.Row>
            <Grid.Col>
              <TextArea
                id="customFields"
                value={customFields}
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
                value={description}
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
