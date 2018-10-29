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
import _ from 'underscore'
import I18n from 'i18n!external_tools'
import React from 'react'
import PropTypes from 'prop-types'
import Modal from '../../shared/components/InstuiModal'
import {ModalBody} from '@instructure/ui-overlays/lib/components/Modal'
import 'compiled/jquery.rails_flash_notifications'
import store from '../../external_apps/lib/ExternalAppsStore'
import ConfigurationForm from '../../external_apps/components/ConfigurationForm'
import Lti2Edit from '../../external_apps/components/Lti2Edit'

export default class EditExternalToolButton extends React.Component {
  static propTypes = {
    tool: PropTypes.object.isRequired,
    canAddEdit: PropTypes.bool.isRequired,
    returnFocus: PropTypes.func.isRequired
  }

  state = {
    tool: this.props.tool,
    modalIsOpen: false
  }

  setContextExternalToolState = data => {
    const tool = _.extend(data, this.props.tool)
    this.setState({
      tool,
      modalIsOpen: true
    })
  }

  openModal = e => {
    e.preventDefault()
    if (this.props.tool.app_type === 'ContextExternalTool') {
      store.fetchWithDetails(this.props.tool).then(data => {
        this.setContextExternalToolState(data)
      })
    } else {
      this.setState({
        tool: this.props.tool,
        modalIsOpen: true
      })
    }
  }

  closeModal = () => {
    this.setState({modalIsOpen: false})
    this.props.returnFocus()
  }

  saveChanges = (configurationType, data) => {
    const success = res => {
      const updatedTool = _.extend(this.state.tool, res)
      // refresh app config index with latest tool state
      store.fetch()
      this.setState({updatedTool})
      this.closeModal()
      // Unsure why this is necessary, but the focus is lost if not wrapped in a timeout
      setTimeout(() => {
        this.refs.editButton.focus()
      }, 300)

      $.flashMessage(I18n.t('The app was updated successfully'))
    }

    const error = () => {
      $.flashError(I18n.t('We were unable to update the app.'))
    }

    const tool = _.extend(this.state.tool, data)
    store.save(configurationType, tool, success.bind(this), error.bind(this))
  }

  handleActivateLti2 = () => {
    store.activate(
      this.state.tool,
      () => {
        this.closeModal()
        $.flashMessage(I18n.t('The app was activated'))
      },
      () => {
        this.closeModal()
        $.flashError(I18n.t('We were unable to activate the app.'))
      }
    )
  }

  handleDeactivateLti2 = () => {
    store.deactivate(
      this.state.tool,
      () => {
        this.closeModal()
        $.flashMessage(I18n.t('The app was deactivated'))
      },
      () => {
        this.closeModal()
        $.flashError(I18n.t('We were unable to deactivate the app.'))
      }
    )
  }

  form = () => {
    if (this.state.tool.app_type === 'ContextExternalTool') {
      return (
        <ConfigurationForm
          ref="configurationForm"
          tool={this.state.tool}
          configurationType="manual"
          handleSubmit={this.saveChanges}
          showConfigurationSelector={false}
          membershipServiceFeatureFlagEnabled={window.ENV.MEMBERSHIP_SERVICE_FEATURE_FLAG_ENABLED}
        >
          <button type="button" className="btn btn-default" onClick={this.closeModal}>
            {I18n.t('Cancel')}
          </button>
        </ConfigurationForm>
      )
    } else {
      // Lti::ToolProxy
      return (
        <Lti2Edit
          ref="lti2Edit"
          tool={this.state.tool}
          handleActivateLti2={this.handleActivateLti2}
          handleDeactivateLti2={this.handleDeactivateLti2}
          handleCancel={this.closeModal}
        />
      )
    }
  }

  render() {
    if (this.props.canAddEdit) {
      const editAriaLabel = I18n.t('Edit %{toolName} App', {toolName: this.state.tool.name})

      return (
        <li role="presentation" className="EditExternalToolButton">
          <a
            href="#"
            ref="editButton"
            tabIndex="-1"
            role="menuitem"
            aria-label={editAriaLabel}
            className="icon-edit"
            onClick={this.openModal}
          >
            {I18n.t('Edit')}
          </a>
          <Modal
            label={I18n.t('Edit App')}
            open={this.state.modalIsOpen}
            onDismiss={this.closeModal}
          >
            <ModalBody>{this.form()}</ModalBody>
          </Modal>
        </li>
      )
    }
    return false
  }
}
