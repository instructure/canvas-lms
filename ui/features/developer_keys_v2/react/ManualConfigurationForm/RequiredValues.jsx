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
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React from 'react'
import $ from 'jquery'

import {FormFieldGroup} from '@instructure/ui-form-field'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {TextArea} from '@instructure/ui-text-area'
import {TextInput} from '@instructure/ui-text-input'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {Grid} from '@instructure/ui-grid'

const I18n = useI18nScope('react_developer_keys')

const validationMessage = [{text: I18n.t('Field cannot be blank.'), type: 'error'}]

export default class RequiredValues extends React.Component {
  constructor(props) {
    super(props)
    const public_jwk = JSON.stringify(this.props.toolConfiguration.public_jwk || {}, null, 4)
    this.state = {
      toolConfiguration: {...this.props.toolConfiguration, public_jwk},
      jwkConfig: this.props.toolConfiguration.public_jwk_url ? 'public_jwk_url' : 'public_jwk',
    }
  }

  isMissingValues = () => {
    let isMissing = false
    if (
      ['target_link_uri', 'oidc_initiation_url', 'description', 'title'].some(
        p => !this.state.toolConfiguration[p]
      )
    ) {
      isMissing = true
    }
    if (!this.state.toolConfiguration.public_jwk && !this.state.toolConfiguration.public_jwk_url) {
      isMissing = true
    }
    return isMissing
  }

  generateToolConfigurationPart = () => {
    if (this.state.toolConfiguration.public_jwk !== '') {
      const public_jwk = JSON.parse(this.state.toolConfiguration.public_jwk)
      return {...this.state.toolConfiguration, public_jwk}
    }
    return {...this.state.toolConfiguration, public_jwk: null}
  }

  hasJwk = () => {
    return this.state.toolConfiguration.public_jwk
  }

  hasJwkUrl = () => !!this.state.toolConfiguration.public_jwk_url

  valid = () => {
    if (this.isMissingValues()) {
      this.props.flashError(I18n.t('Missing required fields. Please fill in all required fields.'))
      return false
      // Only check JWK fields if a JWK field was given,
      // not a JWK URL.
    } else if (this.hasJwk() && !this.hasJwkUrl()) {
      let jwk
      try {
        jwk = JSON.parse(this.state.toolConfiguration.public_jwk)
      } catch (e) {
        if (e instanceof SyntaxError) {
          this.props.flashError(
            I18n.t('Public JWK json is not valid. Please submit properly formatted json.')
          )
          return false
        }
      }
      if (
        typeof jwk !== 'object' ||
        [jwk.kty, jwk.e, jwk.n, jwk.kid, jwk.alg, jwk.use].some(f => typeof f !== 'string')
      ) {
        this.props.flashError(
          I18n.t('Public JWK json must have the following string fields: kty, e, n, kid, alg, use')
        )
        return false
      }
    }

    return true
  }

  handleTitleChange = e => {
    const value = e.target.value
    this.setState(state => ({toolConfiguration: {...state.toolConfiguration, title: value}}))
  }

  handleDescriptionChange = e => {
    const value = e.target.value
    this.setState(state => ({toolConfiguration: {...state.toolConfiguration, description: value}}))
  }

  handleTargetLinkUriChange = e => {
    const value = e.target.value
    this.setState(state => ({
      toolConfiguration: {...state.toolConfiguration, target_link_uri: value},
    }))
  }

  handleOidcInitiationUrlChange = e => {
    const value = e.target.value
    this.setState(state => ({
      toolConfiguration: {...state.toolConfiguration, oidc_initiation_url: value},
    }))
  }

  handlePublicJwkChange = e => {
    const value = e.target.value
    this.setState(state => ({toolConfiguration: {...state.toolConfiguration, public_jwk: value}}))
  }

  handlePublicJwkUrlChange = e => {
    const value = e.target.value
    this.setState(state => ({
      toolConfiguration: {...state.toolConfiguration, public_jwk_url: value},
    }))
  }

  handleConfigTypeChange = (e, option) => {
    this.setState({jwkConfig: option.value})
  }

  configurationInput(option) {
    const {toolConfiguration} = this.state
    const {showMessages} = this.props

    if (option === 'public_jwk') {
      return (
        <TextArea
          name="public_jwk"
          label={I18n.t('Public JWK')}
          value={toolConfiguration.public_jwk || ''}
          maxHeight="10rem"
          resize="vertical"
          autoGrow={true}
          onChange={this.handlePublicJwkChange}
          messages={
            showMessages && !toolConfiguration.public_jwk && !toolConfiguration.public_jwk_url
              ? validationMessage
              : []
          }
        />
      )
    } else {
      return (
        <TextInput
          name="public_jwk_url"
          renderLabel={I18n.t('Public JWK URL')}
          value={toolConfiguration.public_jwk_url || ''}
          onChange={this.handlePublicJwkUrlChange}
          messages={
            showMessages && !toolConfiguration.public_jwk_url && !toolConfiguration.public_jwk
              ? validationMessage
              : []
          }
        />
      )
    }
  }

  render() {
    const {toolConfiguration} = this.state
    const {showMessages} = this.props

    return (
      <FormFieldGroup description={I18n.t('Required Values')}>
        <PresentationContent>
          <hr />
        </PresentationContent>
        <Grid>
          <Grid.Row>
            <Grid.Col>
              <TextInput
                name="title"
                value={toolConfiguration.title || ''}
                renderLabel={I18n.t('* Title')}
                onChange={this.handleTitleChange}
                messages={showMessages && !toolConfiguration.title ? validationMessage : []}
              />
            </Grid.Col>
            <Grid.Col>
              <TextArea
                name="description"
                value={toolConfiguration.description || ''}
                label={I18n.t('* Description')}
                maxHeight="5rem"
                onChange={this.handleDescriptionChange}
                messages={showMessages && !toolConfiguration.description ? validationMessage : []}
              />
            </Grid.Col>
          </Grid.Row>
          <Grid.Row>
            <Grid.Col>
              <TextInput
                name="target_link_uri"
                value={toolConfiguration.target_link_uri || ''}
                renderLabel={I18n.t('* Target Link URI')}
                onChange={this.handleTargetLinkUriChange}
                messages={
                  showMessages && !toolConfiguration.target_link_uri ? validationMessage : []
                }
              />
            </Grid.Col>
            <Grid.Col>
              <TextInput
                name="oidc_initiation_url"
                value={toolConfiguration.oidc_initiation_url || ''}
                renderLabel={I18n.t('* OpenID Connect Initiation Url')}
                onChange={this.handleOidcInitiationUrlChange}
                messages={
                  showMessages && !toolConfiguration.oidc_initiation_url ? validationMessage : []
                }
              />
            </Grid.Col>
          </Grid.Row>
        </Grid>
        <SimpleSelect
          renderLabel={I18n.t('* JWK Method')}
          onChange={this.handleConfigTypeChange}
          value={this.state.jwkConfig}
        >
          <SimpleSelect.Option id="public_jwk" key="public_jwk" value="public_jwk">
            {I18n.t('Public JWK')}
          </SimpleSelect.Option>
          <SimpleSelect.Option id="public_jwk_url" key="public_jwk_url" value="public_jwk_url">
            {I18n.t('Public JWK URL')}
          </SimpleSelect.Option>
        </SimpleSelect>
        {this.configurationInput(this.state.jwkConfig)}
        <PresentationContent>
          <hr />
        </PresentationContent>
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
    public_jwk: PropTypes.object,
    public_jwk_url: PropTypes.string,
  }),
  flashError: PropTypes.func,
  showMessages: PropTypes.bool,
}

RequiredValues.defaultProps = {
  flashError: msg => {
    $.flashError(msg)
  },
}
