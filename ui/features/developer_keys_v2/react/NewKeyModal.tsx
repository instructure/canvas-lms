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

import {useScope as createI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import _ from 'lodash'

import {CloseButton, Button} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {Modal} from '@instructure/ui-modal'
import {View} from '@instructure/ui-view'
import React from 'react'
import NewKeyForm from './NewKeyForm'
import type {AvailableScope} from './reducers/listScopesReducer'
import type {DeveloperKeyCreateOrEditState} from './reducers/createOrEditReducer'
import type actions from './actions/developerKeysActions'
import type {AnyAction, Dispatch} from 'redux'
import type {DeveloperKey} from '../model/api/DeveloperKey'
import {confirmWithPrompt} from '@canvas/instui-bindings/react/ConfirmWithPrompt'

const I18n = createI18nScope('react_developer_keys')

type Props = {
  createOrEditDeveloperKeyState: DeveloperKeyCreateOrEditState
  availableScopes: Record<string, AvailableScope>
  availableScopesPending: boolean
  store: {
    dispatch: Dispatch
  }
  ctx: {
    params: {
      contextId: string
    }
  }
  actions: typeof actions
  selectedScopes: Array<string>
  handleSuccessfulSave: (warningMessage?: string | string[]) => void
}

type ConfigurationMethod = 'manual' | 'json' | 'url'

type State = {
  toolConfiguration: any
  submitted: boolean
  developerKey: any
  toolConfigurationUrl: string | null
  isSaving: boolean
  configurationMethod: ConfigurationMethod
  isRedirectUrisValid: boolean
}

export default class DeveloperKeyModal extends React.Component<Props, State> {
  newForm: NewKeyForm | null = null

  state: State = {
    toolConfiguration: {}, // used to save state when saving the key, display what was there if failure
    submitted: false,
    developerKey: {},
    toolConfigurationUrl: '',
    isSaving: false,
    configurationMethod: 'manual',
    isRedirectUrisValid: true,
  }

  developerKeyUrl() {
    if (this.props.createOrEditDeveloperKeyState.editing) {
      return `/api/v1/developer_keys/${this.developerKey.id}`
    }
    return `/api/v1/accounts/${this.props.ctx.params.contextId}/developer_keys`
  }

  get keySavedSuccessfully() {
    const {developerKeyCreateOrEditSuccessful, developerKeyCreateOrEditPending} =
      this.props.createOrEditDeveloperKeyState
    return developerKeyCreateOrEditSuccessful && !developerKeyCreateOrEditPending
  }

  get developerKey() {
    return {...this.props.createOrEditDeveloperKeyState.developerKey, ...this.state.developerKey}
  }

  get toolConfigForm() {
    return this.newForm
      ? this.newForm
      : {
          valid: () => true,
          generateToolConfiguration: () => {
            return this.toolConfiguration
          },
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
      ...public_jwk_url,
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

  get isSiteAdmin() {
    return this.props.ctx.params.contextId === 'site_admin'
  }

  get hasRedirectUris() {
    const redirect_uris = this.developerKey.redirect_uris
    return Boolean(redirect_uris && redirect_uris.trim().length !== 0)
  }

  get hasInvalidRedirectUris() {
    if (!this.hasRedirectUris) {
      return false
    }

    return (
      this.developerKey.redirect_uris?.split('\n').some((val: string) => val.length > 4096) || false
    )
  }

  alertAboutInvalidRedirectUris() {
    $.flashError(
      I18n.t(
        "One of the supplied redirect_uris is too long. Please ensure you've entered the correct value(s) for your redirect_uris.",
      ),
    )
  }

  updateConfigurationMethod = (configurationMethod: ConfigurationMethod) =>
    this.setState({configurationMethod})

  submitForm = () => {
    const {
      store: {dispatch},
      actions: {createOrEditDeveloperKey},
      createOrEditDeveloperKeyState: {editing},
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
    if (this.hasInvalidRedirectUris) {
      this.alertAboutInvalidRedirectUris()
      return
    }

    this.setState({isSaving: true})
    return dispatch(
      createOrEditDeveloperKey(
        {developer_key: toSubmit},
        this.developerKeyUrl(),
        method,
      ) as unknown as AnyAction,
    )
      .then(() => {
        this.setState({isSaving: false})
        if (this.keySavedSuccessfully) {
          this.props.handleSuccessfulSave()
        }
        this.closeModal()
      })
      .catch(() => {
        this.setState({isSaving: false})
      })
  }

  saveLTIKeyEdit(
    settings: {
      scopes?: any
      custom_fields?: any
    },
    developerKey: DeveloperKey,
  ) {
    const {
      store: {dispatch},
      actions,
    } = this.props
    this.setState({toolConfiguration: settings, isSaving: true})
    return actions
      .updateLtiKey(developerKey, [], this.developerKey.id, settings, settings.custom_fields)
      .then(data => {
        this.setState({isSaving: false})
        const {developer_key, tool_configuration, warning_message} = data
        developer_key.tool_configuration = tool_configuration.settings
        dispatch(actions.listDeveloperKeysReplace(developer_key))
        this.props.handleSuccessfulSave(warning_message)
        this.closeModal()
      })
      .catch(() => {
        this.setState({isSaving: false})
      })
  }

  saveLtiToolConfiguration = () => {
    const {
      store: {dispatch},
      actions,
    } = this.props
    const developer_key = {...this.developerKey}

    if (!developer_key.redirect_uris?.trim()) {
      delete developer_key.redirect_uris
    }

    if (!this.hasRedirectUris && !this.isUrlConfig) {
      this.setState({isRedirectUrisValid: false})
      this.newForm?.valid()
      this.setState({submitted: true})
      return
    } else if (this.hasInvalidRedirectUris) {
      this.setState({isRedirectUrisValid: false})
      this.alertAboutInvalidRedirectUris()
      return
    }
    let settings: {
      scopes?: unknown
    } = {}

    if (this.isJsonConfig || this.isUrlConfig) {
      if (!this.toolConfigForm.valid()) {
        this.setState({submitted: true})
        return
      }
      settings = this.state.toolConfiguration
    } else if (this.isManualConfig) {
      if (!this.toolConfigForm.valid()) {
        this.setState({submitted: true})
        return
      }
      settings = this.toolConfigForm.generateToolConfiguration()
      this.setState({toolConfiguration: settings})
    }
    developer_key.scopes = settings.scopes

    if (this.props.createOrEditDeveloperKeyState.editing) {
      this.saveLTIKeyEdit(settings, developer_key)
    } else {
      const toSave: {
        account_id: string
        developer_key: DeveloperKey
        settings_url?: string
        settings?: unknown
      } = {
        account_id: this.props.ctx.params.contextId,
        developer_key,
      }
      if (this.isUrlConfig) {
        toSave.settings_url = this.state.toolConfigurationUrl || undefined
      } else {
        toSave.settings = settings
      }
      this.setState({isSaving: true})
      return actions
        .saveLtiToolConfiguration(toSave)(dispatch)
        .then(
          data => {
            this.setState({isSaving: false})
            this.props.handleSuccessfulSave(data.warning_message)
            this.closeModal()
          },
          () => this.setState({isSaving: false}),
        )
    }
  }

  updateToolConfigurationUrl = (toolConfigurationUrl: string) => {
    this.setState({toolConfigurationUrl})
  }

  updateToolConfiguration = (update: any, field: string | null = null) => {
    if (field) {
      this.setState(state => ({toolConfiguration: {...state.toolConfiguration, [field]: update}}))
    } else {
      this.setState({toolConfiguration: update})
    }

    if (!this.hasRedirectUris) {
      this.updateDeveloperKey('redirect_uris', update.target_link_uri || '')
    }
  }

  syncRedirectUris = () => {
    this.updateDeveloperKey('redirect_uris', this.state.toolConfiguration?.target_link_uri)
  }

  updateDeveloperKey = (field: string, update: any) => {
    this.setState(state => ({developerKey: {...state.developerKey, [field]: update}}))
  }

  setNewFormRef = (node: NewKeyForm) => {
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
      developerKey: {},
    })
    // Find the appropriate button to focus on based on whether we were editing or adding
    if (
      this.props.createOrEditDeveloperKeyState.editing &&
      this.props.createOrEditDeveloperKeyState.developerKey?.id
    ) {
      document
        .getElementById(
          `edit-developer-key-button-${this.props.createOrEditDeveloperKeyState.developerKey.id}`,
        )
        ?.focus()
    } else {
      document.getElementById('add-developer-key-button')?.focus()
    }
  }

  confirmSave = () => {
    return confirmWithPrompt({
      title: I18n.t('Environment Confirmation'),
      message: I18n.t(
        'Changing Site Admin Developer Keys impacts all customers. To proceed, please confirm the current Canvas environment by typing it in the box below.',
      ),
      label: I18n.t('Environment'),
      placeholder: ENV.RAILS_ENVIRONMENT,
      hintText: I18n.t('The current environment is %{env}, case-insensitive', {
        env: ENV.RAILS_ENVIRONMENT,
      }),
      valueMatchesExpected: (value: string) =>
        value.toLowerCase() === ENV.RAILS_ENVIRONMENT.toLowerCase(),
    })
  }

  handleSave = async () => {
    if (this.isSiteAdmin && !(await this.confirmSave())) {
      return
    }

    if (this.props.createOrEditDeveloperKeyState.isLtiKey) {
      this.saveLtiToolConfiguration()
    } else {
      this.submitForm()
    }
  }

  render() {
    const {
      availableScopes,
      availableScopesPending,
      actions,
      createOrEditDeveloperKeyState: {editing, developerKeyModalOpen, isLtiKey},
    } = this.props
    return (
      <div>
        <Modal
          open={developerKeyModalOpen}
          onDismiss={this.closeModal}
          size="fullscreen"
          label={editing ? I18n.t('Edit Developer Key') : I18n.t('Create Developer Key')}
          shouldCloseOnDocumentClick={false}
        >
          <Modal.Header>
            <CloseButton
              placement="end"
              onClick={this.closeModal}
              screenReaderLabel={I18n.t('Cancel')}
            />
            <Heading level="h1">{I18n.t('Key Settings')}</Heading>
          </Modal.Header>
          <Modal.Body>
            {this.isSaving ? (
              <View as="div" textAlign="center">
                <Spinner
                  renderTitle={editing ? I18n.t('Saving Key') : I18n.t('Creating Key')}
                  margin="0 0 0 medium"
                  aria-live="polite"
                />
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
                hasRedirectUris={this.hasRedirectUris}
                hasInvalidRedirectUris={this.hasInvalidRedirectUris}
                syncRedirectUris={this.syncRedirectUris}
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
            <Button id="lti-key-cancel-button" onClick={this.closeModal} margin="0 small 0 0">
              {I18n.t('Cancel')}
            </Button>
            <Button
              id="lti-key-save-button"
              onClick={this.handleSave}
              color="primary"
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
