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

import {CloseButton} from '@instructure/ui-buttons'
import {Heading, Spinner} from '@instructure/ui-elements'
import {Modal} from '@instructure/ui-overlays'
import {View} from '@instructure/ui-layout'
import React from 'react'
import PropTypes from 'prop-types'
import NewKeyForm from './NewKeyForm'
import NewKeyFooter from './NewKeyFooter'
import LtiKeyFooter from './LtiKeyFooter'

import {objectToCustomVariablesString} from './CustomizationForm'

export default class DeveloperKeyModal extends React.Component {
  state = {
    toolConfiguration: {}, // used to save state when saving the key, display what was there if failure
    submitted: false,
    developerKey: {},
    toolConfigurationUrl: '',
    showCustomizationMessages: false
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

  get isLtiKey() {
    return this.props.createLtiKeyState.isLtiKey
  }

  get isSaving() {
    return (
      this.props.createOrEditDeveloperKeyState.developerKeyCreateOrEditPending ||
      this.props.createLtiKeyState.saveToolConfigurationPending
    )
  }

  get isJsonConfig() {
    return this.props.createLtiKeyState.configurationMethod === 'json'
  }

  get isUrlConfig() {
    return this.props.createLtiKeyState.configurationMethod === 'url'
  }

  get isManualConfig() {
    return this.props.createLtiKeyState.configurationMethod === 'manual'
  }

  get hasRedirectUris() {
    const redirect_uris = this.developerKey.redirect_uris
    return redirect_uris && redirect_uris.trim().length !== 0
  }

  saveCustomizations = () => {
    const {store, actions, createLtiKeyState} = this.props
    if (this.state.toolConfiguration?.custom_fields === null) {
      this.setState({showCustomizationMessages: true})
      return Promise.reject()
    }

    return store
      .dispatch(
        actions.ltiKeysUpdateCustomizations(
          {scopes: createLtiKeyState.enabledScopes},
          createLtiKeyState.disabledPlacements,
          this.developerKey.id,
          createLtiKeyState.toolConfiguration,
          objectToCustomVariablesString(this.toolConfiguration.custom_fields),
          createLtiKeyState.privacyLevel
        )
      )
      .then(() => {
        this.closeModal()
      })
  }

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
    dispatch(actions.saveLtiToolConfigurationStart())
    this.setState({toolConfiguration: settings})
    return actions
      .ltiKeysUpdateCustomizations(
        developerKey,
        [],
        this.developerKey.id,
        settings,
        settings.custom_fields,
        null
      )(dispatch)
      .then(data => {
        dispatch(actions.saveLtiToolConfigurationSuccessful())
        const {developer_key, tool_configuration} = data
        developer_key.tool_configuration = tool_configuration.settings
        dispatch(actions.listDeveloperKeysReplace(developer_key))
        $.flashMessage(I18n.t('Save successful.'))
        this.closeModal()
      })
      .catch(errors => {
        $.flashError(I18n.t('Failed to save changes: %{errors}%', {errors}))
      })
  }

  saveLtiToolConfiguration = () => {
    const {
      store: {dispatch},
      actions
    } = this.props
    const developer_key = {...this.developerKey}
    if (!this.hasRedirectUris) {
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
      return actions.saveLtiToolConfiguration(toSave)(dispatch)
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
    store.dispatch(actions.setLtiConfigurationMethod('manual'))
    this.setState({
      toolConfiguration: null,
      submitted: false,
      toolConfigurationUrl: null,
      developerKey: {},
      showCustomizationMessages: false
    })
  }

  render() {
    const {
      createLtiKeyState,
      availableScopes,
      availableScopesPending,
      store,
      actions,
      createOrEditDeveloperKeyState: {editing, developerKeyModalOpen}
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
                setEnabledScopes={actions.ltiKeysSetEnabledScopes}
                setDisabledPlacements={actions.ltiKeysSetDisabledPlacements}
                setPrivacyLevel={actions.ltiKeysSetPrivacyLevel}
                createLtiKeyState={createLtiKeyState}
                setLtiConfigurationMethod={actions.setLtiConfigurationMethod}
                tool_configuration={this.toolConfiguration}
                editing={editing}
                showRequiredMessages={this.state.submitted}
                updateToolConfiguration={this.updateToolConfiguration}
                updateDeveloperKey={this.updateDeveloperKey}
                updateToolConfigurationUrl={this.updateToolConfigurationUrl}
                toolConfigurationUrl={this.state.toolConfigurationUrl}
                showCustomizationMessages={this.state.showCustomizationMessages}
              />
            )}
          </Modal.Body>
          <Modal.Footer>
            {this.isLtiKey ? (
              <LtiKeyFooter
                onCancelClick={this.closeModal}
                onSaveClick={this.saveCustomizations}
                onAdvanceToCustomization={this.saveLtiToolConfiguration}
                customizing={createLtiKeyState.customizing}
                disable={this.isSaving}
                ltiKeysSetCustomizing={actions.ltiKeysSetCustomizing}
                dispatch={store.dispatch}
                saveOnly={editing || this.isManualConfig}
              />
            ) : (
              <NewKeyFooter
                disable={this.isSaving}
                onCancelClick={this.closeModal}
                onSaveClick={this.submitForm}
              />
            )}
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
    ltiKeysSetCustomizing: PropTypes.func.isRequired,
    createOrEditDeveloperKey: PropTypes.func.isRequired,
    developerKeysModalClose: PropTypes.func.isRequired,
    editDeveloperKey: PropTypes.func.isRequired,
    listDeveloperKeyScopesSet: PropTypes.func.isRequired,
    saveLtiToolConfiguration: PropTypes.func.isRequired,
    resetLtiState: PropTypes.func.isRequired,
    setLtiConfigurationMethod: PropTypes.func.isRequired,
    ltiKeysUpdateCustomizations: PropTypes.func.isRequired,
    saveLtiToolConfigurationStart: PropTypes.func.isRequired
  }).isRequired,
  createLtiKeyState: PropTypes.shape({
    isLtiKey: PropTypes.bool.isRequired,
    customizing: PropTypes.bool.isRequired,
    toolConfiguration: PropTypes.object.isRequired,
    toolConfigurationUrl: PropTypes.string.isRequired,
    saveToolConfigurationPending: PropTypes.bool.isRequired,
    configurationMethod: PropTypes.string.isRequired
  }).isRequired,
  createOrEditDeveloperKeyState: PropTypes.shape({
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
