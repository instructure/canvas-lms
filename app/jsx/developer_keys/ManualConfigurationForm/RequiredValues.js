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

import FormFieldGroup from '@instructure/ui-form-field/lib/components/FormFieldGroup';
import TextInput from '@instructure/ui-forms/lib/components/TextInput';
import TextArea from '@instructure/ui-forms/lib/components/TextArea';
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent';

export default class RequiredValues extends React.Component {
  constructor (props) {
    super(props);
    this.state = {
      toolConfiguration: this.props.toolConfiguration
    }
  }

  generateToolConfigurationPart = () => {
    return this.state.toolConfiguration
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
            label={I18n.t("Title")}
            required
            onChange={this.handleTitleChange}
          />
          <TextArea
            name="description"
            value={toolConfiguration.description}
            label={I18n.t("Description")}
            maxHeight="5rem"
            required
            onChange={this.handleDescriptionChange}
          />
        </FormFieldGroup>
        <FormFieldGroup
          description={<ScreenReaderContent>{I18n.t("Open Id Connect Values")}</ScreenReaderContent>}
          layout="columns"
        >
          <TextInput
            name="target_link_uri"
            value={toolConfiguration.target_link_uri}
            label={I18n.t("Target Link URI")}
            required
            onChange={this.handleTargetLinkUriChange}
          />
          <TextInput
            name="oidc_initiation_url"
            value={toolConfiguration.oidc_initiation_url}
            label={I18n.t("OpenID Connect Initiation Url")}
            required
            onChange={this.handleOidcInitiationUrlChange}
          />
        </FormFieldGroup>
        <TextArea
          name="public_jwk"
          value={toolConfiguration.public_jwk}
          label={I18n.t("Public JWK")}
          maxHeight="10rem"
          required
          resize="vertical"
          autoGrow
          onChange={this.handlePublicJwkChange}
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
  })
}
