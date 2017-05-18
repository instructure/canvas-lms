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
import I18n from 'i18n!external_tools'
import React from 'react'
import Modal from 'react-modal'
import ExternalTool from 'compiled/models/ExternalTool'
import store from 'jsx/external_apps/lib/ExternalAppsStore'
import ConfigurationForm from 'jsx/external_apps/components/ConfigurationForm'
import Lti2Iframe from 'jsx/external_apps/components/Lti2Iframe'
import Lti2Permissions from 'jsx/external_apps/components/Lti2Permissions'
import 'compiled/jquery.rails_flash_notifications'

  const modalOverrides = {
    overlay : {
      backgroundColor: 'rgba(0,0,0,0.5)'
    },
    content : {
      position: 'static',
      top: '0',
      left: '0',
      right: 'auto',
      bottom: 'auto',
      borderRadius: '0',
      border: 'none',
      padding: '0'
    }
  };

export default React.createClass({
    displayName: 'AddExternalToolButton',
    throttleCreation: false,

    propTypes: {
    },

    getInitialState() {
      return {
        modalIsOpen: false,
        tool: {},
        isLti2: false,
        lti2RegistrationUrl: null,
        configurationType: '',
      }
    },

    openModal(e) {
      e.preventDefault();
      this.setState({
        modalIsOpen: true,
        tool: {},
        isLti2: false,
        lti2RegistrationUrl: null
      });
    },

    closeModal() {
      this.setState({ modalIsOpen: false, tool: {} });
    },

    handleLti2ToolInstalled(toolData) {
      this.setState({ tool: toolData });
    },

    _successHandler() {
      this.throttleCreation = false;
      this.setState({ modalIsOpen: false, tool: {}, isLti2: false, lti2RegistrationUrl: null }, function() {
        $.flashMessage(I18n.t('The app was added'));
        store.fetch({ force: true });
      });
    },

    _errorHandler(xhr) {
      const errors = JSON.parse(xhr.responseText).errors;
      let errorMessage = I18n.t('We were unable to add the app.');

      if (this.state.configurationType !== 'manual') {
        const errorName = `config_${this.state.configurationType}`;
        if (errors[errorName]) {
          errorMessage = errors[errorName][0].message;
        } else if (errors[Object.keys(errors)[0]][0])  {
          errorMessage = errors[Object.keys(errors)[0]][0].message;
        }
      }

      this.throttleCreation = false;
      store.fetch({ force: true });
      this.setState({ tool: {}, isLti2: false, lti2RegistrationUrl: null });
      $.flashError(errorMessage);
      return errorMessage
    },

    handleActivateLti2() {
      store.activate(this.state.tool, this._successHandler.bind(this), this._errorHandler.bind(this));
    },

    handleCancelLti2() {
      store.delete(this.state.tool);
      $.flashMessage(I18n.t('%{name} app has been deleted', { name: this.state.tool.name }));
      this.setState({ modalIsOpen: false, tool: {}, isLti2: false, lti2RegistrationUrl: null });
    },

    createTool(configurationType, data) {
      if (configurationType == 'lti2') {
        this.setState({
          isLti2: true,
          lti2RegistrationUrl: data.registrationUrl,
          tool: {}
        });
      } else if (!this.throttleCreation) {
          this.setState({'configurationType': configurationType});
          store.save(configurationType, data, this._successHandler.bind(this), this._errorHandler.bind(this));
          this.throttleCreation = true;
      }
    },

    renderForm() {
      if (this.state.isLti2 && this.state.tool.app_id) {
        return <Lti2Permissions ref="lti2Permissions" tool={this.state.tool} handleCancelLti2={this.handleCancelLti2} handleActivateLti2={this.handleActivateLti2} />;
      } else if (this.state.isLti2) {
        return (
          <Lti2Iframe ref="lti2Iframe" handleInstall={this.handleLti2ToolInstalled} registrationUrl={this.state.lti2RegistrationUrl} >
            <div className="ReactModal__Footer">
              <div id="footer-close-button" className="ReactModal__Footer-Actions">
                <button type="button" className="Button" onClick={this.closeModal}>{I18n.t('Close')}</button>
              </div>
            </div>
          </Lti2Iframe>
        );
      } else {
        return (
          <ConfigurationForm ref="configurationForm" tool={this.state.tool} configurationType="manual" handleSubmit={this.createTool}>
            <button type="button" className="Button" onClick={this.closeModal}>{I18n.t('Cancel')}</button>
          </ConfigurationForm>
        );
      }
    },

    render() {
      return (
        <span className="AddExternalToolButton">
          <a href="#" role="button" aria-label={I18n.t('Add App')} className="Button Button--primary add_tool_link lm icon-plus" onClick={this.openModal}>{I18n.t('App')}</a>
          <Modal className="ReactModal__Content--canvas"
            overlayClassName="ReactModal__Overlay--canvas"
            style={modalOverrides}
            isOpen={this.state.modalIsOpen}
            onRequestClose={this.closeModal}>

            <div className="ReactModal__Layout">
              <div className="ReactModal__Header">
                <div className="ReactModal__Header-Title">
                  <h4>{I18n.t('Add App')}</h4>
                </div>
                <div className="ReactModal__Header-Actions">
                  <button className="Button Button--icon-action" type="button" onClick={this.closeModal}>
                    <i className="icon-x"></i>
                    <span className="screenreader-only">Close</span>
                  </button>
                </div>
              </div>

              {this.renderForm()}
            </div>
          </Modal>
        </span>
      );
    }
  });
