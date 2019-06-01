/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import $ from 'jquery'

import FormFieldGroup from '@instructure/ui-form-field/lib/components/FormFieldGroup';
import TextInput from '@instructure/ui-forms/lib/components/TextInput';
import TextArea from '@instructure/ui-forms/lib/components/TextArea';
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent';

const validationMessage = [{text: I18n.t('Field cannot be blank.'), type: 'error'}]

export default class RequiredValues extends React.Component {
  constructor (props) {
    super(props);
    const public_jwk = JSON.stringify(this.props.toolConfiguration.public_jwk || {}, null, 4)
    this.state = {
      toolConfiguration: {...this.props.toolConfiguration, public_jwk}
    }
  }

  isMissingValues = () => {
    return ['target_link_uri', 'oidc_initiation_url', 'public_jwk', 'description', 'title']
      .some(p => !this.state.toolConfiguration[p])
  }

  generateToolConfigurationPart = () => {
    const public_jwk = JSON.parse(this.state.toolConfiguration.public_jwk)

    return { ...this.state.toolConfiguration, public_jwk }
  }

  valid = () => {
    if (this.isMissingValues()) {
      this.props.flashError(I18n.t('Missing required fields. Please fill in all required fields.'))
      return false
    }
    try {
      JSON.parse(this.state.toolConfiguration.public_jwk)
      return true
    } catch(e) {
      if (e instanceof SyntaxError) {
        this.props.flashError(I18n.t('Public JWK json is not valid. Please submit properly formatted json.'))
        return false
      }
    }
  }

  handleTitleChange = e => {
    const value = e.target.value;
    this.setState(state => ({toolConfiguration: {...state.toolConfiguration, title: value}}))
  }

  handleDescriptionChange = e => {
    const value = e.target.value;
    this.setState(state => ({toolConfiguration: {...state.toolConfiguration, description: value}}))
  }

  handleTargetLinkUriChange = e => {
    const value = e.target.value;
    this.setState(state => ({toolConfiguration: {...state.toolConfiguration, target_link_uri: value}}))
  }

  handleOidcInitiationUrlChange = e => {
    const value = e.target.value;
    this.setState(state => ({toolConfiguration: {...state.toolConfiguration, oidc_initiation_url: value}}))
  }

  handlePublicJwkChange = e => {
    const value = e.target.value;
    this.setState(state => ({toolConfiguration: {...state.toolConfiguration, public_jwk: value}}))
  }

  render() {
    const { toolConfiguration } = this.state;
    const { showMessages } = this.props

    return (
      <FormFieldGroup
        description={I18n.t("Required Values")}
      >
        <hr />
        <FormFieldGroup
          description={<ScreenReaderContent>{I18n.t('Display Values')}</ScreenReaderContent>}
          layout="columns"
        >
          <TextInput
            name="title"
            value={toolConfiguration.title}
            label={I18n.t("* Title")}
            required
            onChange={this.handleTitleChange}
            messages={showMessages && !toolConfiguration.title ? validationMessage : []}
          />
          <TextArea
            name="description"
            value={toolConfiguration.description}
            label={I18n.t("* Description")}
            maxHeight="5rem"
            required
            onChange={this.handleDescriptionChange}
            messages={showMessages && !toolConfiguration.description ? validationMessage : []}
          />
        </FormFieldGroup>
        <FormFieldGroup
          description={<ScreenReaderContent>{I18n.t("* Open Id Connect Values")}</ScreenReaderContent>}
          layout="columns"
        >
          <TextInput
            name="target_link_uri"
            value={toolConfiguration.target_link_uri}
            label={I18n.t("* Target Link URI")}
            required
            onChange={this.handleTargetLinkUriChange}
            messages={showMessages && !toolConfiguration.target_link_uri ? validationMessage : []}
          />
          <TextInput
            name="oidc_initiation_url"
            value={toolConfiguration.oidc_initiation_url}
            label={I18n.t("* OpenID Connect Initiation Url")}
            required
            onChange={this.handleOidcInitiationUrlChange}
            messages={showMessages && !toolConfiguration.oidc_initiation_url ? validationMessage : []}
          />
        </FormFieldGroup>
        <TextArea
          name="public_jwk"
          value={toolConfiguration.public_jwk}
          label={I18n.t("* Public JWK")}
          maxHeight="10rem"
          required
          resize="vertical"
          autoGrow
          onChange={this.handlePublicJwkChange}
          messages={showMessages && !toolConfiguration.public_jwk ? validationMessage : []}
        />
        <hr />
      </FormFieldGroup>
    )
  }
}

RequiredValues.propTypes = {
  toolConfiguration: PropTypes.shape({
    title: PropTypes.string,
    description: PropTypes.string,
    target_link_uri: PropTypes.string,
    oidc_initiation_url: PropTypes.string,
    public_jwk: PropTypes.string
  }),
  flashError: PropTypes.func,
  showMessages: PropTypes.bool
}

RequiredValues.defaultProps = {
  flashError: (msg) => {
    $.flashError(msg)
  }
}
