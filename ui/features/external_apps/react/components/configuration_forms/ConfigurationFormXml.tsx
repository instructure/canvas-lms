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
import {TextArea} from '@instructure/ui-text-area'
import {Grid} from '@instructure/ui-grid'
import '@canvas/rails-flash-notifications'
import type {I18nType, TextAreaChangeHandler, TextInputChangeHandler} from './types'
import MembershipServiceAccess from './MembershipServiceAccess'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const I18n: I18nType = useI18nScope('external_tools')

export interface ConfigurationFormXmlProps {
  name?: string
  consumerKey?: string
  sharedSecret?: string
  xml?: string
  allowMembershipServiceAccess?: boolean
  membershipServiceFeatureFlagEnabled: boolean
}

interface ConfigurationFormXmlErrors {
  name?: FormMessage[]
  xml?: FormMessage[]
}

export interface ConfigurationFormXmlState {
  name: string
  consumerKey: string
  sharedSecret: string
  xml: string
  allowMembershipServiceAccess: boolean
  errors: ConfigurationFormXmlErrors
}

export interface ConfigurationFormXmlFormData
  extends Omit<ConfigurationFormXmlState, 'errors' | 'allowMembershipServiceAccess'> {
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
    errors: {},
  }

  isValid = () => {
    const fields: (keyof ConfigurationFormXmlErrors & keyof ConfigurationFormXmlState)[] = [
        'name',
        'xml',
      ],
      formErrors: string[] = []

    const errors: ConfigurationFormXmlErrors = {}
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
        this.setState(prevState => ({...prevState, [field]: value}))
      }
    }

  handleXmlChange: TextAreaChangeHandler = e => {
    this.setState({xml: e.target.value})
  }

  render() {
    return (
      <div className="ConfigurationFormXml">
        <Grid hAlign="space-between" colSpacing="none" rowSpacing="small">
          <Grid.Row>
            <Grid.Col>
              <TextInput
                id="name"
                value={this.state.name}
                renderLabel={I18n.t('Name')}
                onChange={this.handleChange('name')}
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
                value={this.props.sharedSecret}
                renderLabel={I18n.t('Shared Secret')}
                onChange={this.handleChange('sharedSecret')}
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
              <TextArea
                id="xml"
                value={this.state.xml}
                label={I18n.t('XML Configuration')}
                onChange={this.handleXmlChange}
                // Initially 12 rows of text, will grow if needed
                height="12rem"
                resize="vertical"
                messages={this.state.errors.xml}
              />
            </Grid.Col>
          </Grid.Row>
        </Grid>
      </div>
    )
  }
}
