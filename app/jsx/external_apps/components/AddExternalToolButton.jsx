/** @jsx React.DOM */

define([
  'jquery',
  'i18n!external_tools',
  'react',
  'react-modal',
  'compiled/models/ExternalTool',
  'jsx/external_apps/lib/ExternalAppsStore',
  'jsx/external_apps/components/ConfigurationForm',
  'jsx/external_apps/components/Lti2Iframe',
  'jsx/external_apps/components/Lti2Permissions',
  'compiled/jquery.rails_flash_notifications'
], function ($, I18n, React, Modal, ExternalTool, store, ConfigurationForm, Lti2Iframe, Lti2Permissions) {

  return React.createClass({
    displayName: 'AddExternalToolButton',

    getInitialState() {
      return {
        modalIsOpen: false,
        tool: {},
        isLti2: false,
        lti2RegistrationUrl: null
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
      this.setState({ modalIsOpen: false, tool: {}, isLti2: false, lti2RegistrationUrl: null }, function() {
        $.flashMessage(I18n.t('The app was added'));
        store.fetch({ force: true });
      });
    },

    _errorHandler() {
      store.fetch({ force: true });
      this.setState({ tool: {}, isLti2: false, lti2RegistrationUrl: null });
      $.flashError(I18n.t('We were unable to add the app.'));
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
      } else {
        store.save(configurationType, data, this._successHandler.bind(this), this._errorHandler.bind(this));
      }
    },

    renderForm() {
      if (this.state.isLti2 && this.state.tool.app_id) {
        return <Lti2Permissions ref="lti2Permissions" tool={this.state.tool} handleCancelLti2={this.handleCancelLti2} handleActivateLti2={this.handleActivateLti2} />;
      } else if (this.state.isLti2) {
        return <Lti2Iframe ref="lti2Iframe" handleInstall={this.handleLti2ToolInstalled} registrationUrl={this.state.lti2RegistrationUrl} />;
      } else {
        return (
          <ConfigurationForm ref="configurationForm" tool={this.state.tool} configurationType="manual" handleSubmit={this.createTool}>
            <button type="button" className="btn btn-default" onClick={this.closeModal}>{I18n.t('Cancel')}</button>
          </ConfigurationForm>
        );
      }
    },

    render() {
      return (
        <span className="AddExternalToolButton">
          <a href="#" role="button" aria-label={I18n.t('Add App')} className="btn btn-primary add_tool_link lm" onClick={this.openModal}>{I18n.t('Add App')}</a>
          <Modal className="ReactModal__Content--canvas"
            overlayClassName="ReactModal__Overlay--canvas"
            isOpen={this.state.modalIsOpen}
            onRequestClose={this.closeModal}>

            <div className="ReactModal__Layout">
              <div className="ReactModal__InnerSection ReactModal__Header ReactModal__Header--force-no-corners">
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
});
