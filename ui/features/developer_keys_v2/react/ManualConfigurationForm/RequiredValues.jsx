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
import {useScope as createI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React, {createRef} from 'react'

import {FormFieldGroup} from '@instructure/ui-form-field'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {TextArea} from '@instructure/ui-text-area'
import {TextInput} from '@instructure/ui-text-input'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {Grid} from '@instructure/ui-grid'

const I18n = createI18nScope('react_developer_keys')

const validationMessage = {
  text: [{text: I18n.t('Field cannot be blank.'), type: 'error'}],
  url: [{text: I18n.t('Please enter a valid URL (e.g. https://example.com)'), type: 'error'}],
  jwk: [{text: I18n.t('Please enter a valid JWK.'), type: 'error'}],
}

export default class RequiredValues extends React.Component {
  constructor(props) {
    super(props)

    const public_jwk = JSON.stringify(this.props.toolConfiguration.public_jwk || {}, null, 4)

    this.state = {
      isTitleValid: true,
      isDescriptionValid: true,
      isTargetLinkUriValid: true,
      isOidcInitiationUrlValid: true,
      isPublicJwkValid: true,
      isPublicJwkUrlValid: true,
      toolConfiguration: {
        ...this.props.toolConfiguration,
        public_jwk,
      },
      jwkConfig: this.props.toolConfiguration.public_jwk_url ? 'public_jwk_url' : 'public_jwk',
    }
  }

  titleRef = createRef()
  descriptionRef = createRef()
  targetLinkUriRef = createRef()
  oidcInitiationUrlRef = createRef()
  publicJwkRef = createRef()
  publicJwkUrlRef = createRef()

  generateToolConfigurationPart = () => {
    if (this.state.toolConfiguration.public_jwk !== '') {
      const public_jwk = JSON.parse(this.state.toolConfiguration.public_jwk)
      return {...this.state.toolConfiguration, public_jwk}
    }
    return {...this.state.toolConfiguration, public_jwk: null}
  }

  hasJwk = () => !!this.state.toolConfiguration.public_jwk

  hasJwkUrl = () => !!this.state.toolConfiguration.public_jwk_url

  hasValidJwk = () => {
    let jwk
    try {
      jwk = JSON.parse(this.state.toolConfiguration.public_jwk)
    } catch (e) {
      if (e instanceof SyntaxError) {
        return false
      }
    }
    if (
      typeof jwk !== 'object' ||
      [jwk.kty, jwk.e, jwk.n, jwk.kid, jwk.alg, jwk.use].some(f => typeof f !== 'string')
    ) {
      return false
    }
    return true
  }

  invalidate = (fieldStateKey, fieldRef) => {
    this.setState({[fieldStateKey]: false})
    if (this.isValid) {
      fieldRef.current.focus()
      this.isValid = false
    }
  }

  validateField = (fieldValue, fieldStateKey, fieldRef, isUrl) => {
    if (!fieldValue || (isUrl && !URL.canParse(fieldValue))) {
      this.invalidate(fieldStateKey, fieldRef)
    } else {
      this.setState({[fieldStateKey]: true})
    }
  }

  validateJwkField = (fieldValue, fieldStateKey, fieldRef) => {
    if (!fieldValue || !this.hasValidJwk()) {
      this.invalidate(fieldStateKey, fieldRef)
    } else {
      this.setState({[fieldStateKey]: true})
    }
  }

  valid = () => {
    const {title, description, target_link_uri, oidc_initiation_url, public_jwk, public_jwk_url} =
      this.state.toolConfiguration
    this.isValid = true

    this.validateField(title, 'isTitleValid', this.titleRef, false)
    this.validateField(description, 'isDescriptionValid', this.descriptionRef, false)
    this.validateField(target_link_uri, 'isTargetLinkUriValid', this.targetLinkUriRef, true)
    this.validateField(
      oidc_initiation_url,
      'isOidcInitiationUrlValid',
      this.oidcInitiationUrlRef,
      true,
    )

    if (this.state.jwkConfig === 'public_jwk_url') {
      this.validateField(public_jwk_url, 'isPublicJwkUrlValid', this.publicJwkUrlRef, true)
    } else if (this.state.jwkConfig === 'public_jwk') {
      this.validateJwkField(public_jwk, 'isPublicJwkValid', this.publicJwkRef)
    }

    return this.isValid
  }

  handleTitleChange = e => {
    const value = e.target.value
    this.setState(state => ({toolConfiguration: {...state.toolConfiguration, title: value}}))
    this.validateField(value, 'isTitleValid', this.titleRef, false)
  }

  handleDescriptionChange = e => {
    const value = e.target.value
    this.setState(state => ({toolConfiguration: {...state.toolConfiguration, description: value}}))
    this.validateField(value, 'isDescriptionValid', this.descriptionRef, false)
  }

  handleTargetLinkUriChange = e => {
    const value = e.target.value
    this.setState(state => ({
      toolConfiguration: {...state.toolConfiguration, target_link_uri: value},
    }))
    this.validateField(value, 'isTargetLinkUriValid', this.targetLinkUriRef, true)
  }

  handleOidcInitiationUrlChange = e => {
    const value = e.target.value
    this.setState(state => ({
      toolConfiguration: {...state.toolConfiguration, oidc_initiation_url: value},
    }))
    this.validateField(value, 'isOidcInitiationUrlValid', this.oidcInitiationUrlRef, true)
  }

  handlePublicJwkChange = e => {
    const value = e.target.value
    this.setState(state => ({toolConfiguration: {...state.toolConfiguration, public_jwk: value}}))
    this.validateJwkField(value, 'isPublicJwkValid', this.publicJwkRef)
  }

  handlePublicJwkUrlChange = e => {
    const value = e.target.value
    this.setState(state => ({
      toolConfiguration: {...state.toolConfiguration, public_jwk_url: value},
    }))
    this.validateField(value, 'isPublicJwkUrlValid', this.publicJwkUrlRef, true)
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
          required
          ref={this.publicJwkRef}
          value={toolConfiguration.public_jwk || ''}
          maxHeight="10rem"
          resize="vertical"
          autoGrow
          onChange={this.handlePublicJwkChange}
          messages={showMessages && !this.state.isPublicJwkValid ? validationMessage.jwk : []}
        />
      )
    } else {
      return (
        <TextInput
          name="public_jwk_url"
          renderLabel={I18n.t('Public JWK URL')}
          isRequired
          ref={this.publicJwkUrlRef}
          value={toolConfiguration.public_jwk_url || ''}
          onChange={this.handlePublicJwkUrlChange}
          messages={showMessages && !this.state.isPublicJwkUrlValid ? validationMessage.url : []}
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
                renderLabel={I18n.t('Title')}
                isRequired
                ref={this.titleRef}
                onChange={this.handleTitleChange}
                messages={showMessages && !this.state.isTitleValid ? validationMessage.text : []}
              />
            </Grid.Col>
            <Grid.Col>
              <TextArea
                name="description"
                value={toolConfiguration.description || ''}
                label={I18n.t('Description')}
                required
                ref={this.descriptionRef}
                maxHeight="5rem"
                onChange={this.handleDescriptionChange}
                messages={
                  showMessages && !this.state.isDescriptionValid ? validationMessage.text : []
                }
              />
            </Grid.Col>
          </Grid.Row>
          <Grid.Row>
            <Grid.Col>
              <TextInput
                name="target_link_uri"
                value={toolConfiguration.target_link_uri || ''}
                renderLabel={I18n.t('Target Link URI')}
                isRequired
                ref={this.targetLinkUriRef}
                onChange={this.handleTargetLinkUriChange}
                messages={
                  showMessages && !this.state.isTargetLinkUriValid ? validationMessage.url : []
                }
              />
            </Grid.Col>
            <Grid.Col>
              <TextInput
                name="oidc_initiation_url"
                value={toolConfiguration.oidc_initiation_url || ''}
                renderLabel={I18n.t('OpenID Connect Initiation Url')}
                isRequired
                ref={this.oidcInitiationUrlRef}
                onChange={this.handleOidcInitiationUrlChange}
                messages={
                  showMessages && !this.state.isOidcInitiationUrlValid ? validationMessage.url : []
                }
              />
            </Grid.Col>
          </Grid.Row>
        </Grid>
        <SimpleSelect
          renderLabel={I18n.t('JWK Method')}
          isRequired
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
  showMessages: PropTypes.bool,
}
