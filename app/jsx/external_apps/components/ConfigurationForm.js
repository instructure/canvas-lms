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

import I18n from 'i18n!external_tools'
import $ from 'jquery'
import React from 'react'
import PropTypes from 'prop-types'
import ConfigurationFormManual from '../../external_apps/components/ConfigurationFormManual'
import ConfigurationFormUrl from '../../external_apps/components/ConfigurationFormUrl'
import ConfigurationFormXml from '../../external_apps/components/ConfigurationFormXml'
import ConfigurationFormLti2 from '../../external_apps/components/ConfigurationFormLti2'
import ConfigurationTypeSelector from '../../external_apps/components/ConfigurationTypeSelector'

export default class ConfigurationForm extends React.Component {
  static propTypes = {
    configurationType: PropTypes.string,
    handleSubmit: PropTypes.func.isRequired,
    tool: PropTypes.object.isRequired,
    showConfigurationSelector: PropTypes.bool,
    hideComponent: PropTypes.bool,
    membershipServiceFeatureFlagEnabled: PropTypes.bool,
    children: PropTypes.node
  }

  static defaultProps = {
    showConfigurationSelector: true
  }

  constructor(props, context) {
    super(props, context)
    const _state = this.defaultState()
    if (props.tool) {
      _state.name = props.tool.name
      _state.consumerKey = props.tool.consumer_key
      _state.sharedSecret = props.tool.shared_secret
      _state.url = props.tool.url
      _state.domain = props.tool.domain
      _state.privacy_level = props.tool.privacy_level
      _state.customFields = props.tool.custom_fields
      _state.description = props.tool.description
      _state.configUrl = props.tool.config_url
      _state.xml = props.tool.xml
      _state.registrationUrl = props.tool.registration_url
      _state.allow_membership_service_access = props.tool.allow_membership_service_access
    }

    this.state = _state
  }

  defaultState = () => ({
    configurationType: this.props.configurationType,
    showConfigurationSelector: this.props.showConfigurationSelector,
    name: '',
    consumerKey: '',
    sharedSecret: '',
    url: '',
    domain: '',
    privacy_level: '',
    customFields: {},
    description: '',
    configUrl: '',
    registrationUrl: '',
    xml: '',
    allow_membership_service_access: false
  })

  reset = () => {
    this.setState({
      name: '',
      consumerKey: '',
      sharedSecret: '',
      url: '',
      domain: '',
      privacy_level: '',
      customFields: {},
      description: '',
      configUrl: '',
      registrationUrl: '',
      xml: '',
      allow_membership_service_access: false
    })
  }

  handleSwitchConfigurationType = e => {
    this.setState({
      configurationType: e.target.value
    })
  }

  handleSubmit = e => {
    e.preventDefault()
    let form
    switch (this.state.configurationType) {
      case 'manual':
        form = this.refs.configurationFormManual
        break
      case 'url':
        form = this.refs.configurationFormUrl
        break
      case 'xml':
        form = this.refs.configurationFormXml
        break
      case 'lti2':
        form = this.refs.configurationFormLti2
        break
    }

    if (form.isValid()) {
      const strip = obj => {
        const newObj = {}

        for (const prop in obj) {
          if (obj[prop] && typeof obj[prop] === 'string') {
            newObj[prop] = obj[prop].trim()
          } else {
            newObj[prop] = obj[prop]
          }
        }
        return newObj
      }
      let formData = form.getFormData()
      formData = strip(formData)
      this.props.handleSubmit(this.state.configurationType, formData, e)
    } else {
      $('.ReactModal__Overlay').animate({scrollTop: 0}, 'slow')
    }
  }

  iframeTarget = () => {
    if (this.state.configurationType === 'lti2') {
      return 'lti2_registration_frame'
    }
    return null
  }

  form = () => {
    if (this.state.configurationType === 'manual') {
      return (
        <ConfigurationFormManual
          ref="configurationFormManual"
          name={this.state.name}
          consumerKey={this.state.consumerKey}
          sharedSecret={this.state.sharedSecret}
          url={this.state.url}
          domain={this.state.domain}
          privacyLevel={this.state.privacy_level}
          customFields={this.state.customFields}
          description={this.state.description}
          allowMembershipServiceAccess={this.state.allow_membership_service_access}
          membershipServiceFeatureFlagEnabled={this.props.membershipServiceFeatureFlagEnabled}
        />
      )
    }

    if (this.state.configurationType === 'url') {
      return (
        <ConfigurationFormUrl
          ref="configurationFormUrl"
          name={this.state.name}
          consumerKey={this.state.consumerKey}
          sharedSecret={this.state.sharedSecret}
          configUrl={this.state.configUrl}
          allowMembershipServiceAccess={this.state.allow_membership_service_access}
          membershipServiceFeatureFlagEnabled={this.props.membershipServiceFeatureFlagEnabled}
        />
      )
    }

    if (this.state.configurationType === 'xml') {
      return (
        <ConfigurationFormXml
          ref="configurationFormXml"
          name={this.state.name}
          consumerKey={this.state.consumerKey}
          sharedSecret={this.state.sharedSecret}
          xml={this.state.xml}
          allowMembershipServiceAccess={this.state.allow_membership_service_access}
          membershipServiceFeatureFlagEnabled={this.props.membershipServiceFeatureFlagEnabled}
        />
      )
    }

    if (this.state.configurationType === 'lti2') {
      return (
        <ConfigurationFormLti2
          ref="configurationFormLti2"
          registrationUrl={this.state.registrationUrl}
        />
      )
    }
  }

  configurationTypeSelector = () => {
    if (this.props.showConfigurationSelector) {
      return (
        <ConfigurationTypeSelector
          ref="configurationTypeSelector"
          handleChange={this.handleSwitchConfigurationType}
          configurationType={this.props.configurationType}
        />
      )
    }
  }

  submitButton = () => {
    if (this.state.configurationType === 'lti2') {
      return (
        <button
          ref="submitLti2"
          type="button"
          id="submitExternalAppBtn"
          className="btn btn-primary"
          onClick={this.handleSubmit}
        >
          {I18n.t('Launch Registration Tool')}
        </button>
      )
    } else {
      return (
        <button
          ref="submit"
          type="button"
          id="submitExternalAppBtn"
          className="btn btn-primary"
          onClick={this.handleSubmit}
        >
          {I18n.t('Submit')}
        </button>
      )
    }
  }

  render() {
    return (
      <div style={this.props.hideComponent ? {display: 'none'} : {}}>
        <form
          className="ConfigurationForm"
          onSubmit={this.handleSubmit}
          target={this.iframeTarget()}
          method="post"
          action={ENV.LTI_LAUNCH_URL}
        >
          <div className="ReactModal__Body">
            {this.configurationTypeSelector()}
            <div className="formFields">{this.form()}</div>
          </div>
          <div className="ReactModal__Footer">
            <div className="ReactModal__Footer-Actions">
              {this.props.children}
              {this.submitButton()}
            </div>
          </div>
        </form>
      </div>
    )
  }
}
