/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import $ from 'jquery'

import {CloseButton, Button} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {Modal} from '@instructure/ui-modal'
import {View} from '@instructure/ui-view'
import React from 'react'
import PropTypes from 'prop-types'
import NewKeyForm from './NewKeyForm'

export default class DeveloperKeyModal extends React.Component {
  state = {
    toolConfiguration: {}, // used to save state when saving the key, display what was there if failure
    submitted: false,
    developerKey: {},
    toolConfigurationUrl: '',
    isSaving: false,
    configurationMethod: 'manual'
  }

  developerKeyUrl() {
    if (this.props.createOrEditDeveloperKeyState.editing) {
      return `/api/v1/developer_keys/${this.developerKey.id}`
    }
    return `/api/v1/accounts/${this.props.ctx.params.contextId}/developer_keys`
  }

  get developerKey() {
    return {...this.props.createOrEditDeveloperKeyState.developerKey, ...this.state.developerKey}
  }

  get manualForm() {
    return this.newForm
      ? this.newForm
      : {
          valid: () => true,
          generateToolConfiguration: () => {
            return this.toolConfiguration
          }
        }
  }

  get toolConfiguration() {
    const public_jwk = this.developerKey.public_jwk
      ? {public_jwk: this.developerKey.public_jwk}
      : {}
    const public_jwk_url = this.developerKey.public_jwk_url
      ? {public_jwk_url: this.developerKey.public_jwk_url}
      : {}
    return {
      ...(this.developerKey.tool_configuration || {}),
      ...this.state.toolConfiguration,
      ...public_jwk,
      ...public_jwk_url
    }
  }

  get isSaving() {
    return this.state.isSaving
  }

  get isJsonConfig() {
    return this.state.configurationMethod === 'json'
  }

  get isUrlConfig() {
    return this.state.configurationMethod === 'url'
  }

  get isManualConfig() {
    return this.state.configurationMethod === 'manual'
  }

  get hasRedirectUris() {
    const redirect_uris = this.developerKey.redirect_uris
    return redirect_uris && redirect_uris.trim().length !== 0
  }

  updateConfigurationMethod = configurationMethod => this.setState({configurationMethod})

  submitForm = () => {
    const {
      store: {dispatch},
      actions: {createOrEditDeveloperKey},
      createOrEditDeveloperKeyState: {editing}
    } = this.props
    const method = editing ? 'put' : 'post'
    const toSubmit = this.developerKey

    if (!toSubmit.require_scopes) {
      toSubmit.require_scopes = false
    }
    if (!toSubmit.name) {
      toSubmit.name = 'Unnamed Tool'
    }
    if (toSubmit.require_scopes) {
      if (this.props.selectedScopes.length === 0) {
        $.flashError(I18n.t('At least one scope must be selected.'))
        return
      }
      toSubmit.scopes = this.props.selectedScopes
    }

    return dispatch(
      createOrEditDeveloperKey({developer_key: toSubmit}, this.developerKeyUrl(), method)
    ).then(() => {
      this.closeModal()
    })
  }

  saveLTIKeyEdit(settings, developerKey) {
    const {
      store: {dispatch},
      actions
    } = this.props
    this.setState({toolConfiguration: settings, isSaving: true})
    return actions
      .updateLtiKey(developerKey, [], this.developerKey.id, settings, settings.custom_fields, null)
      .then(data => {
        this.setState({isSaving: false})
        const {developer_key, tool_configuration} = data
        developer_key.tool_configuration = tool_configuration.settings
        dispatch(actions.listDeveloperKeysReplace(developer_key))
        $.flashMessage(I18n.t('Save successful.'))
        this.closeModal()
      })
      .catch(errors => {
        this.setState({isSaving: false})
        $.flashError(I18n.t('Failed to save changes: %{errors}%', {errors}))
      })
  }

  saveLtiToolConfiguration = () => {
    const {
      store: {dispatch},
      actions
    } = this.props
    const developer_key = {...this.developerKey}
    if (!this.hasRedirectUris && !this.isUrlConfig) {
      $.flashError(I18n.t('A redirect_uri is required, please supply one.'))
      this.setState({submitted: true})
      return
    }
    let settings = {}
    if (this.isJsonConfig) {
      if (!this.state.toolConfiguration) {
        this.setState({submitted: true})
        return
      }
      settings = this.state.toolConfiguration
    } else if (this.isManualConfig) {
      if (!this.manualForm.valid()) {
        this.setState({submitted: true})
        return
      }
      settings = this.manualForm.generateToolConfiguration()
      this.setState({toolConfiguration: settings})
    }
    developer_key.scopes = settings.scopes

    if (this.props.createOrEditDeveloperKeyState.editing) {
      this.saveLTIKeyEdit(settings, developer_key)
    } else {
      const toSave = {
        account_id: this.props.ctx.params.contextId,
        developer_key
      }
      if (this.isUrlConfig) {
        if (!this.state.toolConfigurationUrl) {
          $.flashError(I18n.t('A json url is required, please supply one.'))
          this.setState({submitted: true})
          return
        }
        toSave.settings_url = this.state.toolConfigurationUrl
      } else {
        toSave.settings = settings
      }
      this.setState({isSaving: true})
      return actions
        .saveLtiToolConfiguration(toSave)(dispatch)
        .then(
          () => {
            this.setState({isSaving: false})
            this.closeModal()
          },
          () => this.setState({isSaving: false})
        )
    }
  }

  updateToolConfigurationUrl = toolConfigurationUrl => {
    this.setState({toolConfigurationUrl})
  }

  updateToolConfiguration = (update, field = null) => {
    if (field) {
      this.setState(state => ({toolConfiguration: {...state.toolConfiguration, [field]: update}}))
    } else {
      this.setState({toolConfiguration: update})
    }

    this.updateDeveloperKey('redirect_uris', update.target_link_uri || '')
  }

  updateDeveloperKey = (field, update) => {
    this.setState(state => ({developerKey: {...state.developerKey, [field]: update}}))
  }

  setNewFormRef = node => {
    this.newForm = node
  }

  closeModal = () => {
    const {actions, store} = this.props
    store.dispatch(actions.developerKeysModalClose())
    store.dispatch(actions.resetLtiState())
    store.dispatch(actions.editDeveloperKey())
    this.setState({
      toolConfiguration: null,
      submitted: false,
      toolConfigurationUrl: null,
      developerKey: {}
    })
  }

  render() {
    const {
      availableScopes,
      availableScopesPending,
      actions,
      createOrEditDeveloperKeyState: {editing, developerKeyModalOpen, isLtiKey}
    } = this.props
    return (
      <div>
        <Modal
          open={developerKeyModalOpen}
          onDismiss={this.closeModal}
          size="fullscreen"
          label={editing ? I18n.t('Create developer key') : I18n.t('Edit developer key')}
          shouldCloseOnDocumentClick={false}
        >
          <Modal.Header>
            <CloseButton placement="end" onClick={this.closeModal}>
              {I18n.t('Cancel')}
            </CloseButton>
            <Heading>{I18n.t('Key Settings')}</Heading>
          </Modal.Header>
          <Modal.Body>
            {this.isSaving ? (
              <View as="div" textAlign="center">
                <Spinner renderTitle={I18n.t('Creating Key')} margin="0 0 0 medium" />
              </View>
            ) : (
              <NewKeyForm
                ref={this.setNewFormRef}
                developerKey={this.developerKey}
                availableScopes={availableScopes}
                availableScopesPending={availableScopesPending}
                dispatch={this.props.store.dispatch}
                listDeveloperKeyScopesSet={actions.listDeveloperKeyScopesSet}
                tool_configuration={this.toolConfiguration}
                editing={editing}
                showRequiredMessages={this.state.submitted}
                showMissingRedirectUrisMessage={
                  this.state.submitted && isLtiKey && !this.hasRedirectUris && !this.isUrlConfig
                }
                updateToolConfiguration={this.updateToolConfiguration}
                updateDeveloperKey={this.updateDeveloperKey}
                updateToolConfigurationUrl={this.updateToolConfigurationUrl}
                toolConfigurationUrl={this.state.toolConfigurationUrl}
                configurationMethod={this.state.configurationMethod}
                updateConfigurationMethod={this.updateConfigurationMethod}
                isLtiKey={isLtiKey}
                isRedirectUriRequired={isLtiKey && !this.isUrlConfig}
              />
            )}
          </Modal.Body>
          <Modal.Footer>
            <Button onClick={this.closeModal} margin="0 small 0 0">
              {I18n.t('Cancel')}
            </Button>
            <Button
              onClick={isLtiKey ? this.saveLtiToolConfiguration : this.submitForm}
              variant="primary"
              disabled={this.isSaving}
            >
              {I18n.t('Save')}
            </Button>
          </Modal.Footer>
        </Modal>
      </div>
    )
  }
}

DeveloperKeyModal.propTypes = {
  availableScopes: PropTypes.objectOf(
    PropTypes.arrayOf(
      PropTypes.shape({
        resource: PropTypes.string,
        scope: PropTypes.string
      })
    )
  ).isRequired,
  store: PropTypes.shape({
    dispatch: PropTypes.func.isRequired
  }).isRequired,
  actions: PropTypes.shape({
    createOrEditDeveloperKey: PropTypes.func.isRequired,
    developerKeysModalClose: PropTypes.func.isRequired,
    editDeveloperKey: PropTypes.func.isRequired,
    listDeveloperKeyScopesSet: PropTypes.func.isRequired,
    saveLtiToolConfiguration: PropTypes.func.isRequired,
    resetLtiState: PropTypes.func.isRequired,
    updateLtiKey: PropTypes.func.isRequired
  }).isRequired,
  createOrEditDeveloperKeyState: PropTypes.shape({
    isLtiKey: PropTypes.bool.isRequired,
    developerKeyCreateOrEditSuccessful: PropTypes.bool.isRequired,
    developerKeyCreateOrEditFailed: PropTypes.bool.isRequired,
    developerKeyCreateOrEditPending: PropTypes.bool.isRequired,
    developerKeyModalOpen: PropTypes.bool.isRequired,
    developerKey: NewKeyForm.propTypes.developerKey,
    editing: PropTypes.bool.isRequired
  }).isRequired,
  availableScopesPending: PropTypes.bool.isRequired,
  ctx: PropTypes.shape({
    params: PropTypes.shape({
      contextId: PropTypes.string.isRequired
    })
  }).isRequired,
  selectedScopes: PropTypes.arrayOf(PropTypes.string).isRequired
}
