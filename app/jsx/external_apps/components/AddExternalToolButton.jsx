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
          <a href="#" role="button" aria-label={I18n.t('Add External Tool')} className="btn btn-primary add_tool_link lm pull-right" onClick={this.openModal}>{I18n.t('Add External Tool')}</a>
          <Modal className="ReactModal__Content--external_tools" closeTimeoutMS={150} isOpen={this.state.modalIsOpen} onRequestClose={this.closeModal}>
            <div className="modal-content">
              <div className="modal-header">
                <button type="button" className="close" onClick={this.closeModal}>
                  <span aria-hidden="true">&times;</span>
                  <span className="screenreader-only">{I18n.t('Close')}</span>
                </button>
                <h4 className="modal-title">{I18n.t('Add External Tool')}</h4>
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
