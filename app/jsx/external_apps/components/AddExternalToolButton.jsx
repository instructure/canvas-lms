/** @jsx React.DOM */

define([
  'jquery',
  'i18n!external_tools',
  'react',
  'react-modal',
  'compiled/models/ExternalTool',
  'jsx/external_apps/lib/store',
  'jsx/external_apps/components/ConfigurationForm',
  'compiled/jquery.rails_flash_notifications'
], function ($, I18n, React, Modal, ExternalTool, store, ConfigurationForm) {

  return React.createClass({
    displayName: 'AddExternalToolButton',

    getInitialState() {
      var tool = new ExternalTool();
      return {
        modalIsOpen: false,
        tool: tool
      }
    },

    openModal(e) {
      e.preventDefault();
      if (this.isMounted()) {
        this.setState({modalIsOpen: true});
      }
    },

    closeModal() {
      if (this.isMounted()) {
        this.setState({modalIsOpen: false});
      }
    },

    createTool(configurationType, data) {
      var success = function() {
        this.closeModal();
        $.flashMessage(I18n.t('The app was added'));
      };

      var error = function() {
        $.flashError(I18n.t('We were unable to add the app.'));
      };

      store.createExternalTool(configurationType, data, success.bind(this), error.bind(this));
    },

    render() {
      return (
        <span className="AddExternalToolButton">
          <a href="#" role="button" aria-label={I18n.t('Add App')} className="btn btn-primary add_tool_link lm pull-right" onClick={this.openModal}>{I18n.t('Add App')}</a>
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

              <ConfigurationForm tool={this.state.tool} configurationType="manual" handleSubmit={this.createTool}>
                <button type="button" className="btn btn-default" onClick={this.closeModal}>{I18n.t('Cancel')}</button>
              </ConfigurationForm>
            </div>
          </Modal>
        </span>
      )
    }
  });
});
