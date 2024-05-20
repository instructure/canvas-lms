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
import type {TextInputChangeHandler} from './types'

const I18n = useI18nScope('external_tools')

export interface ConfigurationFormLti2Props {
  registrationUrl?: string
}

export interface ConfigurationFormLti2State {
  registrationUrl: string
  errors: {
    registrationUrl?: FormMessage[]
  }
}

export interface ConfigurationFormLti2FormData extends Omit<ConfigurationFormLti2State, 'errors'> {}

export default class ConfigurationFormLti2 extends React.Component<
  ConfigurationFormLti2Props,
  ConfigurationFormLti2State
> {
  state: ConfigurationFormLti2State = {
    registrationUrl: this.props.registrationUrl ?? '',
    errors: {},
  }

  handleChange: TextInputChangeHandler = (_, val) => {
    this.setState({
      registrationUrl: val,
    })
  }

  isValid = () => {
    if (!this.state.registrationUrl) {
      this.setState({
        errors: {
          registrationUrl: [{text: I18n.t('This field is required'), type: 'error'}],
        },
      })

      return false
    } else {
      return true
    }
  }

  getFormData = (): ConfigurationFormLti2FormData => ({
    registrationUrl: this.state.registrationUrl,
  })

  render() {
    return (
      <div className="ConfigurationFormLti2">
        <TextInput
          id="registrationUrl"
          type="url"
          // @ts-ignore
          // The LTI 2 registration form is the _only_ form that actually submits values
          // using form.submit as opposed to XHR/fetch, so this name is required for it to work
          // properly. InstUI will propagate this value down to the input element. This is largely
          // due to the fact that the result of the POST will be rendered within a div, and it's easier
          // to just let the form handle that, rather than replicate that functionality in JS.
          name="tool_consumer_url"
          value={this.state.registrationUrl}
          onChange={this.handleChange}
          renderLabel={I18n.t('Registration URL')}
          placeholder={I18n.t('https://lti-tool-provider-example.herokuapp.com/register')}
          messages={this.state.errors.registrationUrl}
          isRequired={true}
        />
      </div>
    )
  }
}
