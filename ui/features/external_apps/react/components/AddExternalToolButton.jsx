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

import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import store from '../lib/ExternalAppsStore'
import {bool, string} from 'prop-types'
import ConfigurationForm from './configuration_forms/ConfigurationForm'
import ConfirmationForm from './ConfirmationForm'
import Lti2Iframe from './Lti2Iframe'
import Lti2Permissions from './Lti2Permissions'
import DuplicateConfirmationForm from './DuplicateConfirmationForm'
import '@canvas/rails-flash-notifications'
import fetchToolConfiguration from '../lib/fetchToolConfiguration'
import toolConfigurationError from '../lib/toolConfigurationError'
import install13Tool from '../lib/install13Tool'
import {IconAddLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import {Button} from '@instructure/ui-buttons'
import {AccessibleContent} from '@instructure/ui-a11y-content'

const I18n = useI18nScope('external_tools')

export default class AddExternalToolButton extends React.Component {
  static propTypes = {
    modalIsOpen: bool,
    isLti2: bool,
    configurationType: string,
    duplicateTool: bool,
  }

  static defaultProps = {
    modalIsOpen: false,
    isLti2: false,
    configurationType: '',
    duplicateTool: false,
  }

  constructor(props) {
    super(props)
    this.state = {
      modalIsOpen: props.modalIsOpen,
      tool: {},
      isLti2: props.isLti2,
      type: '',
      toolConfiguration: null,
      clientId: null,
      lti2RegistrationUrl: 'about:blank',
      configurationType: props.configurationType,
      duplicateTool: props.duplicateTool,
      attemptedToolSaveData: {},
      attemptedToolConfigurationType: '',
    }
  }

  throttleCreation = false

  get isInstalling13Tool() {
    return this.state.type === 'byClientId'
  }

  openModal = e => {
    e.preventDefault()
    this.setState({
      modalIsOpen: true,
      tool: {},
      isLti2: false,
      lti2RegistrationUrl: null,
    })
  }

  closeModal = () => {
    this.setState({
      modalIsOpen: false,
      tool: {},
      duplicateTool: false,
      attemptedToolSaveData: {},
      attemptedToolConfigurationType: '',
      clientId: null,
      toolConfiguration: null,
      type: '',
    })
  }

  handleLti2ToolInstalled = toolData => {
    if (toolData.status === 'failure') {
      this.setState({modalIsOpen: false}, () => {
        $.flashErrorSafe(
          toolData.message || I18n.t('There was an unknown error registering the tool')
        )
      })
    } else {
      this.setState({tool: toolData})
    }
  }

  _successHandler = () => {
    this.throttleCreation = false
    this.setState(
      {
        modalIsOpen: false,
        tool: {},
        isLti2: false,
        lti2RegistrationUrl: null,
        duplicateTool: false,
        attemptedToolSaveData: {},
        attemptedToolConfigurationType: '',
      },
      () => {
        $.flashMessage(I18n.t('The app was added'))
        store.reset()
        store.fetch()
      }
    )
  }

  _duplicate_check_error(errors) {
    if (errors.tool_currently_installed) {
      this.setState({duplicateTool: true})
      this.throttleCreation = false
      return true
    }
    return false
  }

  _errorHandler = xhr => {
    const errors = JSON.parse(xhr.responseText).errors
    if (this._duplicate_check_error(errors)) {
      return
    }

    let errorMessage = I18n.t('We were unable to add the app.')
    if (this.state.configurationType !== 'manual') {
      const errorName = `config_${this.state.configurationType}`
      if (errors[errorName]) {
        errorMessage = errors[errorName][0].message
      } else if (errors[Object.keys(errors)[0]][0]) {
        errorMessage = errors[Object.keys(errors)[0]][0].message
      }
    }

    this.throttleCreation = false
    store.reset()
    store.fetch({force: true})
    this.setState({tool: {}, isLti2: false, lti2RegistrationUrl: null})
    $.flashError(errorMessage)
    return errorMessage
  }

  handleActivateLti2 = () => {
    store.activate(this.state.tool, this._successHandler.bind(this), this._errorHandler.bind(this))
  }

  handleCancelLti2 = () => {
    store.delete(this.state.tool)
    $.flashMessage(I18n.t('%{name} app has been deleted', {name: this.state.tool.name}))
    this.setState({modalIsOpen: false, tool: {}, isLti2: false, lti2RegistrationUrl: null})
  }

  createTool = (configurationType, data, e) => {
    if (configurationType === 'lti2') {
      this.setState({
        isLti2: true,
        lti2RegistrationUrl: data.registrationUrl,
        tool: {},
      })
      e.currentTarget.closest('form').submit()
    } else if (configurationType === 'byClientId') {
      return fetchToolConfiguration(
        data.client_id,
        ENV.TOOL_CONFIGURATION_SHOW_URL,
        toolConfigurationError
      ).then(toolConfiguration => {
        this.setState({
          type: 'byClientId',
          toolConfiguration,
          clientId: data.client_id,
        })
      })
    } else if (!this.throttleCreation) {
      this.setState({
        configurationType,
        attemptedToolSaveData: data,
        attemptedToolConfigurationType: configurationType,
      })
      store.save(
        configurationType,
        data,
        this._successHandler.bind(this),
        this._errorHandler.bind(this)
      )
      this.throttleCreation = true
    }
  }

  create13Tool = (verify_uniqueness = true) => {
    return install13Tool(this.state.clientId, ENV.EXTERNAL_TOOLS_CREATE_URL, verify_uniqueness)
      .then(
        () => {
          this._successHandler()
          this.closeModal()
        },
        response => {
          const errors = response.response.data.errors
          this._duplicate_check_error(errors)
        }
      )
      .catch(() => {
        $.flashError(I18n.t('We were unable to add the app.'))
        this.closeModal()
      })
  }

  renderForm = () => {
    if (this.state.duplicateTool) {
      return (
        <DuplicateConfirmationForm
          onCancel={this.closeModal}
          toolData={this.state.attemptedToolSaveData}
          configurationType={this.state.attemptedToolConfigurationType}
          onSuccess={this._successHandler}
          onError={this._errorHandler}
          forceSaveTool={this.isInstalling13Tool && (() => this.create13Tool(false))}
          store={store}
        />
      )
    } else if (this.state.isLti2 && this.state.tool.app_id) {
      return (
        <Lti2Permissions
          tool={this.state.tool}
          handleCancelLti2={this.handleCancelLti2}
          handleActivateLti2={this.handleActivateLti2}
        />
      )
    } else if (this.isInstalling13Tool && this.state.toolConfiguration) {
      const {clientId} = this.state
      const toolName = this.state.toolConfiguration.settings.title

      return (
        <ConfirmationForm
          onCancel={() => {
            this.closeModal()
          }}
          onConfirm={() => this.create13Tool()}
          message={I18n.t(
            'Tool "%{toolName}" found for client ID %{clientId}. Would you like to install it?',
            {toolName, clientId}
          )}
          confirmLabel={I18n.t('Install')}
        />
      )
    } else {
      return (
        <div>
          <ConfigurationForm
            tool={this.state.tool}
            configurationType="manual"
            handleSubmit={this.createTool}
            hideComponent={this.state.isLti2}
            membershipServiceFeatureFlagEnabled={window.ENV.MEMBERSHIP_SERVICE_FEATURE_FLAG_ENABLED}
          >
            <button type="button" className="Button" onClick={this.closeModal}>
              {I18n.t('Cancel')}
            </button>
          </ConfigurationForm>
          <Lti2Iframe
            handleInstall={this.handleLti2ToolInstalled}
            registrationUrl={this.state.lti2RegistrationUrl}
            hideComponent={!this.state.isLti2}
            toolName={I18n.t('Register Tool')}
          >
            <div className="ReactModal__Footer">
              <div id="footer-close-button" className="ReactModal__Footer-Actions">
                <button type="button" className="Button" onClick={this.closeModal}>
                  {I18n.t('Close')}
                </button>
              </div>
            </div>
          </Lti2Iframe>
        </div>
      )
    }
  }

  render() {
    return (
      <View>
        <Button
          id="add-app-button"
          color="primary"
          margin="x-small"
          renderIcon={IconAddLine}
          onClick={this.openModal}
        >
          <AccessibleContent alt={I18n.t('Add App')}>{I18n.t('App')}</AccessibleContent>
        </Button>
        <Modal
          open={this.state.modalIsOpen}
          onDismiss={this.closeModal}
          label={I18n.t('Add App')}
          size="large"
        >
          <Modal.Body>{this.renderForm()}</Modal.Body>
        </Modal>
      </View>
    )
  }
}
