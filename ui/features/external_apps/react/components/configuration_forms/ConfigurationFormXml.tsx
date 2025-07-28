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
import React from 'react'
import {TextInput} from '@instructure/ui-text-input'
import type {FormMessage} from '@instructure/ui-form-field'
import {TextArea} from '@instructure/ui-text-area'
import {Grid} from '@instructure/ui-grid'
import '@canvas/rails-flash-notifications'
import type {I18nType, TextAreaChangeHandler, TextInputChangeHandler} from './types'
import MembershipServiceAccess from './MembershipServiceAccess'

const I18n: I18nType = createI18nScope('external_tools')

export interface ConfigurationFormXmlProps {
  name?: string
  consumerKey?: string
  sharedSecret?: string
  xml?: string
  allowMembershipServiceAccess?: boolean
  membershipServiceFeatureFlagEnabled: boolean
}

interface ConfigurationFormXmlErrors {
  missing?: FormMessage[]
}

export interface ConfigurationFormXmlState {
  name: string
  consumerKey: string
  sharedSecret: string
  xml: string
  allowMembershipServiceAccess: boolean
  showMessages?: boolean
  isNameValid: boolean
  isXmlValid: boolean
}

export interface ConfigurationFormXmlFormData
  extends Omit<
    ConfigurationFormXmlState,
    'allowMembershipServiceAccess' | 'isNameValid' | 'isXmlValid' | 'showMessages'
  > {
  name: string
  consumerKey: string
  sharedSecret: string
  xml: string
  allow_membership_service_access?: boolean
  verifyUniqueness: 'true'
}

export default class ConfigurationFormXml extends React.Component<
  ConfigurationFormXmlProps,
  ConfigurationFormXmlState
> {
  state: ConfigurationFormXmlState = {
    name: this.props.name ?? '',
    consumerKey: this.props.consumerKey ?? '',
    sharedSecret: this.props.sharedSecret ?? '',
    xml: this.props.xml ?? '',
    allowMembershipServiceAccess: this.props.allowMembershipServiceAccess ?? false,
    showMessages: false,
    isNameValid: true,
    isXmlValid: true,
  }

  nameRef = React.createRef<TextInput>()
  xmlRef = React.createRef<TextArea>()

  errors: ConfigurationFormXmlErrors = {
    missing: [{text: I18n.t('This field is required'), type: 'error'}],
  }

  valid = true

  validateField = (
    fieldValue: string,
    fieldStateKey: 'isNameValid' | 'isXmlValid',
    fieldRef: React.RefObject<TextInput | TextArea>,
  ) => {
    if (!fieldValue) {
      this.invalidate(fieldStateKey, fieldRef)
    } else {
      this.setState(prevState => ({...prevState, [fieldStateKey]: true}))
    }
  }

  invalidate = (
    fieldStateKey: 'isNameValid' | 'isXmlValid',
    fieldRef: React.RefObject<TextInput | TextArea>,
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

    this.validateField(this.state.name, 'isNameValid', this.nameRef)
    this.validateField(this.state.xml, 'isXmlValid', this.xmlRef)

    return this.valid
  }

  getFormData = (): ConfigurationFormXmlFormData => {
    const data: ConfigurationFormXmlFormData = {
      name: this.state.name,
      consumerKey: this.state.consumerKey,
      sharedSecret: this.state.sharedSecret,
      xml: this.state.xml,
      verifyUniqueness: 'true',
    }

    if (this.props.membershipServiceFeatureFlagEnabled) {
      data.allow_membership_service_access = this.state.allowMembershipServiceAccess
    }

    return data
  }

  handleChange: (field: Exclude<keyof ConfigurationFormXmlState, 'xml'>) => TextInputChangeHandler =
    field => {
      return (_, value) => {
        if (field === 'name') {
          this.validateField(value, 'isNameValid', this.nameRef)
        }
        this.setState(prevState => ({...prevState, [field]: value}))
      }
    }

  handleXmlChange: TextAreaChangeHandler = e => {
    this.validateField(e.target.value, 'isXmlValid', this.xmlRef)
    this.setState({xml: e.target.value})
  }

  handleXmlPaste = (e: React.ClipboardEvent<HTMLTextAreaElement>): void => {
    const value = e.clipboardData.getData('text')
    this.validateField(value, 'isXmlValid', this.xmlRef)
    this.setState({xml: value})
  }

  render() {
    const {
      name,
      xml,
      consumerKey,
      sharedSecret,
      allowMembershipServiceAccess,
      showMessages,
      isNameValid,
      isXmlValid,
    } = this.state

    return (
      <div className="ConfigurationFormXml">
        <Grid hAlign="space-between" colSpacing="none" rowSpacing="small">
          <Grid.Row>
            <Grid.Col>
              <TextInput
                id="name"
                value={name}
                renderLabel={I18n.t('Name')}
                ref={this.nameRef}
                onChange={this.handleChange('name')}
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
                renderLabel={I18n.t('Shared Secret')}
                onChange={this.handleChange('sharedSecret')}
              />
            </Grid.Col>
          </Grid.Row>

          <Grid.Row>
            <Grid.Col>
              <MembershipServiceAccess
                membershipServiceFeatureFlagEnabled={this.props.membershipServiceFeatureFlagEnabled}
                checked={allowMembershipServiceAccess}
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
              <TextArea
                id="xml"
                value={xml}
                label={I18n.t('XML Configuration')}
                required
                ref={this.xmlRef}
                onChange={this.handleXmlChange}
                // @ts-expect-error
                onPaste={this.handleXmlPaste}
                // Initially 12 rows of text, will grow if needed
                height="12rem"
                resize="vertical"
                messages={showMessages && !isXmlValid ? this.errors.missing : []}
              />
            </Grid.Col>
          </Grid.Row>
        </Grid>
      </div>
    )
  }
}
