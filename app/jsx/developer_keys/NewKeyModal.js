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
import Button from '@instructure/ui-core/lib/components/Button'
import Heading from '@instructure/ui-core/lib/components/Heading'
import Modal, {ModalHeader, ModalBody, ModalFooter} from '@instructure/ui-core/lib/components/Modal'
import Spinner from '@instructure/ui-core/lib/components/Spinner'
import React from 'react'
import PropTypes from 'prop-types'
import DeveloperKeyFormFields from './NewKeyForm'

export default class DeveloperKeyModal extends React.Component {
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

  get submissionForm () {
    return this.newForm ? this.newForm.keyForm : <form />
  }

  get requireScopes () {
    return this.newForm && this.newForm.requireScopes
  }

  submitForm = () => {
    const method = this.developerKey() ? 'put' : 'post'
    const formData = new FormData(this.submissionForm)

    if (!this.requireScopes) {
      formData.delete('developer_key[scopes][]')
      formData.append('developer_key[require_scopes]', false)
    } else if (this.props.selectedScopes.length === 0 &&
      this.props.createOrEditDeveloperKeyState.developerKey.scopes.length === 0
    ) {
      $.flashError(I18n.t('At least one scope must be selected.'))
      return
    } else {
      const scopesArrayKey = 'developer_key[scopes][]'

      this.props.selectedScopes.forEach((scope) => {
        formData.append(scopesArrayKey, scope)
      })
      formData.append('developer_key[require_scopes]', true)
    }
    this.props.store.dispatch(
      this.props.actions.createOrEditDeveloperKey(formData, this.developerKeyUrl(), method)
    )
  }

  modalBody() {
    if (this.props.createOrEditDeveloperKeyState.developerKeyCreateOrEditPending) {
      return this.spinner()
    }
    return this.developerKeyForm()
  }

  spinner() {
    return (
      <div className="center-content">
        <Spinner title={I18n.t('Creating Key')} margin="0 0 0 medium" />
      </div>
    )
  }

  developerKeyForm() {
    const {
      availableScopes,
      availableScopesPending,
      createOrEditDeveloperKeyState: { developerKey }
    } = this.props;

    return <DeveloperKeyFormFields
      ref={this.setNewFormRef}
      developerKey={developerKey}
      availableScopes={availableScopes}
      availableScopesPending={availableScopesPending}
      dispatch={this.props.store.dispatch}
      listDeveloperKeyScopesSet={this.props.actions.listDeveloperKeyScopesSet}
    />
  }

  setNewFormRef = node => { this.newForm = node }
  modalContainerRef = node => { this.modalContainer = node }

  modalIsOpen() {
    return this.props.createOrEditDeveloperKeyState.developerKeyModalOpen
  }

  closeModal = () => {
    this.props.store.dispatch(this.props.actions.developerKeysModalClose())
    this.props.store.dispatch(this.props.actions.setEditingDeveloperKey())
  }

  modalContainerRef = div => {
    this.modalContainer = div
  }

  render() {
    return (
      <div ref={this.modalContainerRef}>
        <Modal
          open={this.modalIsOpen()}
          onDismiss={this.closeModal}
          size="fullscreen"
          label={this.modalTitle()}
          shouldCloseOnOverlayClick
          closeButtonLabel={I18n.t('Cancel')}
          applicationElement={() => [this.modalContainer]}
          mountNode={this.props.mountNode}
        >
          <ModalHeader>
            <Heading>{I18n.t('Key Settings')}</Heading>
          </ModalHeader>
          <ModalBody>{this.modalBody()}</ModalBody>
          <ModalFooter>
            <Button onClick={this.closeModal}>{I18n.t('Cancel')}</Button>&nbsp;
            <Button onClick={this.submitForm} variant="primary">
              {I18n.t('Save Key')}
            </Button>
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
    createOrEditDeveloperKey: PropTypes.func.isRequired,
    developerKeysModalClose: PropTypes.func.isRequired,
    setEditingDeveloperKey: PropTypes.func.isRequired,
    listDeveloperKeyScopesSet: PropTypes.func.isRequired
  }).isRequired,
  createOrEditDeveloperKeyState: PropTypes.shape({
    developerKeyCreateOrEditSuccessful: PropTypes.bool.isRequired,
    developerKeyCreateOrEditFailed: PropTypes.bool.isRequired,
    developerKeyCreateOrEditPending: PropTypes.bool.isRequired,
    developerKeyModalOpen: PropTypes.bool.isRequired,
    developerKey: DeveloperKeyFormFields.propTypes.developerKey
  }).isRequired,
  availableScopesPending: PropTypes.bool.isRequired,
  ctx: PropTypes.shape({
    params: PropTypes.shape({
      contextId: PropTypes.string.isRequired
    })
  }).isRequired,
  mountNode: PropTypes.func,
  selectedScopes: PropTypes.arrayOf(PropTypes.string).isRequired
}

DeveloperKeyModal.defaultProps = {
  mountNode: () => document.body
}

