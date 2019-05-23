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

import CloseButton from '@instructure/ui-buttons/lib/components/CloseButton'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import Modal, {ModalHeader, ModalBody, ModalFooter} from '@instructure/ui-overlays/lib/components/Modal'
import Spinner from '@instructure/ui-elements/lib/components/Spinner'
import View from '@instructure/ui-layout/lib/components/View'
import React from 'react'
import PropTypes from 'prop-types'
import NewKeyForm from './NewKeyForm'
import NewKeyFooter from './NewKeyFooter'
import LtiKeyFooter from './LtiKeyFooter'

export default class DeveloperKeyModal extends React.Component {
  state = {
    toolConfiguration: null, // used to save state when saving the key, display what was there if failure
    submitted: false
  }

  developerKeyUrl() {
    if (this.developerKey()) {
      return `/api/v1/developer_keys/${this.developerKey().id}`
    }
    return `/api/v1/accounts/${this.props.ctx.params.contextId}/developer_keys`
  }

  developerKey() {
    return this.props.createOrEditDeveloperKeyState.developerKey
  }

  modalTitle() {
    return this.developerKey() ? I18n.t('Create developer key') : I18n.t('Edit developer key')
  }

  get manualForm () {
    return this.newForm ? this.newForm : {
      valid: () => true,
      generateToolConfiguration: () => {
        return this.toolConfiguration
      }
    }
  }

  get toolConfiguration () {
    const {
      createOrEditDeveloperKeyState: { developerKey }
    } = this.props;
    return this.state.toolConfiguration ? this.state.toolConfiguration : (developerKey && developerKey.tool_configuration || {})
  }

  get submissionForm () {
    return this.newForm ? this.newForm.keyForm : <form />
  }

  get requireScopes () {
    return this.newForm && this.newForm.requireScopes
  }

  get testClusterOnly () {
    return this.newForm && this.newForm.testClusterOnly
  }

  get isLtiKey() {
    return this.props.createLtiKeyState.isLtiKey
  }

  get isSaving() {
    return this.props.createOrEditDeveloperKeyState.developerKeyCreateOrEditPending || this.props.createLtiKeyState.saveToolConfigurationPending
  }

  get isJsonConfig () {
    return this.props.createLtiKeyState.configurationMethod === 'json'
  }

  get isUrlConfig () {
    return this.props.createLtiKeyState.configurationMethod === 'url'
  }

  get isManualConfig () {
    return this.props.createLtiKeyState.configurationMethod === 'manual'
  }


  hasRedirectUris(formData) {
    const redirect_uris = formData.get("developer_key[redirect_uris]")
    return redirect_uris && redirect_uris.trim().length !== 0
  }

  saveCustomizations = () => {
    const customFields = new FormData(this.submissionForm).get('custom_fields')
    const { store, actions, createLtiKeyState, createOrEditDeveloperKeyState } = this.props

    store.dispatch(actions.ltiKeysUpdateCustomizations(
      {scopes: createLtiKeyState.enabledScopes},
      createLtiKeyState.disabledPlacements,
      createOrEditDeveloperKeyState.developerKey.id,
      createLtiKeyState.toolConfiguration,
      customFields,
      createLtiKeyState.privacyLevel
    ))
    this.closeModal()
  }

  submitForm = () => {
    const { store: { dispatch }, actions: { createOrEditDeveloperKey } } = this.props
    const method = this.developerKey() ? 'put' : 'post'
    const formData = new FormData(this.submissionForm)

    if (!this.requireScopes) {
      formData.delete('developer_key[scopes][]')
      formData.append('developer_key[require_scopes]', false)
    } else if (this.props.selectedScopes.length === 0) {
      $.flashError(I18n.t('At least one scope must be selected.'))
      return
    } else {
      const scopesArrayKey = 'developer_key[scopes][]'

      this.props.selectedScopes.forEach((scope) => {
        formData.append(scopesArrayKey, scope)
      })
      formData.append('developer_key[require_scopes]', true)
    }

    if (this.testClusterOnly !== undefined) {
      formData.append('developer_key[test_cluster_only]', this.testClusterOnly)
    }

    return dispatch(createOrEditDeveloperKey(formData, this.developerKeyUrl(), method))
      .then(() => { this.closeModal() })
  }

  saveLTIKeyEdit (settings, developerKey) {
    const { store: { dispatch }, actions } = this.props
    dispatch(actions.saveLtiToolConfigurationStart())
    this.setState({toolConfiguration: settings})
    return actions.ltiKeysUpdateCustomizations(
      developerKey,
      [],
      this.props.createOrEditDeveloperKeyState.developerKey.id,
      settings,
      '',
      null
    )(dispatch).then((data) => {
      dispatch(actions.saveLtiToolConfigurationSuccessful())
      const { developer_key, tool_configuration } = data
      developer_key.tool_configuration = tool_configuration.settings
      dispatch(actions.listDeveloperKeysReplace(developer_key))
      this.closeModal()
      $.flashMessage(I18n.t('Save successful.'))
    }).catch(errors => {
      $.flashError(I18n.t('Failed to save changes: %{errors}%', {errors}))
    })
  }

  saveLtiToolConfiguration = () => {
    const { store: { dispatch }, actions } = this.props
    const formData = new FormData(this.submissionForm)
    const redirectUris = formData.get("developer_key[redirect_uris]")
    if (!this.hasRedirectUris(formData)) {
      $.flashError(I18n.t('A redirect_uri is required, please supply one.'))
      this.setState({submitted: true})
      return
    }
    let settings = {};
    let developerKey = {}
    if (this.isJsonConfig) {
      if (!this.state.toolConfiguration) {
        this.setState({submitted: true})
        return
      }
      settings = this.state.toolConfiguration
    } else if(this.isManualConfig) {
      if (!this.manualForm.valid()) {
        this.setState({submitted: true})
        return
      }
      settings = this.manualForm.generateToolConfiguration();
      developerKey = {
        scopes: settings.scopes,
        redirectUris
      }
      this.setState({toolConfiguration: settings})
    }

    if (this.props.createOrEditDeveloperKeyState.editing) {
      this.saveLTIKeyEdit(settings, developerKey)
    } else {
      return actions.saveLtiToolConfiguration({
        account_id: this.props.ctx.params.contextId,
        developer_key: {
          name: formData.get("developer_key[name]"),
          email: formData.get("developer_key[email]"),
          notes: formData.get("developer_key[notes]"),
          redirect_uris: redirectUris,
          test_cluster_only: this.testClusterOnly,
          access_token_count: 0
        },
        settings,
        settings_url: formData.get("tool_configuration_url"),
      })(dispatch)
    }
  }

  updateToolConfiguration = (update) => {
    this.setState({ toolConfiguration: update })
  }

  setNewFormRef = node => { this.newForm = node }

  closeModal = () => {
    const { actions, store } = this.props
    store.dispatch(actions.developerKeysModalClose())
    store.dispatch(actions.resetLtiState())
    store.dispatch(actions.editDeveloperKey())
    this.setState({toolConfiguration: null, submitted: false})
  }

  render() {
    const {
      createLtiKeyState,
      availableScopes,
      availableScopesPending,
      store,
      actions,
      createOrEditDeveloperKeyState: { developerKey, editing, developerKeyModalOpen }
    } = this.props
    return (
      <div>
        <Modal
          open={developerKeyModalOpen}
          onDismiss={this.closeModal}
          size="fullscreen"
          label={this.modalTitle()}
        >
          <ModalHeader>
            <CloseButton placement="end" onClick={this.closeModal}>
              {I18n.t('Cancel')}
            </CloseButton>
            <Heading>{I18n.t('Key Settings')}</Heading>
          </ModalHeader>
          <ModalBody>
            {this.isSaving
              ? <View as="div" textAlign="center">
                  <Spinner title={I18n.t('Creating Key')} margin="0 0 0 medium" />
                </View>
              : <NewKeyForm
                  ref={this.setNewFormRef}
                  developerKey={developerKey}
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
                />
            }
          </ModalBody>
          <ModalFooter>
            {this.isLtiKey
              ? <LtiKeyFooter
                  onCancelClick={this.closeModal}
                  onSaveClick={this.saveCustomizations}
                  onAdvanceToCustomization={this.saveLtiToolConfiguration}
                  customizing={createLtiKeyState.customizing}
                  disable={this.isSaving}
                  ltiKeysSetCustomizing={actions.ltiKeysSetCustomizing}
                  dispatch={store.dispatch}
                  saveOnly={editing || this.isManualConfig}
                />
              : <NewKeyFooter
                  disable={this.isSaving}
                  onCancelClick={this.closeModal}
                  onSaveClick={this.submitForm}
                />
            }
          </ModalFooter>
        </Modal>
      </div>
    )
  }
}

DeveloperKeyModal.propTypes = {
  availableScopes: PropTypes.objectOf(PropTypes.arrayOf(
    PropTypes.shape({
      resource: PropTypes.string,
      scope: PropTypes.string
    })
  )).isRequired,
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
