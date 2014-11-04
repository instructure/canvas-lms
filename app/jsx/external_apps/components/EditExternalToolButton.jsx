/** @jsx React.DOM */

define([
  'jquery',
  'i18n!external_tools',
  'react',
  'react-modal',
  'jsx/external_apps/lib/store',
  'jsx/external_apps/components/ConfigurationForm',
  'compiled/jquery.rails_flash_notifications'
], function ($, I18n, React, Modal, store, ConfigurationForm) {

  return React.createClass({
    displayName: 'EditExternalToolButton',

    propTypes: {
      tool: React.PropTypes.object.isRequired
    },

    getInitialState() {
      return {
        modalIsOpen: false
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

    saveChanges(configurationType, data) {
      var success = function() {
        this.closeModal();

        // Unsure why this is necessary, but the focus is lost if not wrapped in a timeout
        setTimeout(function() {
          this.refs.editButton.getDOMNode().focus();
        }.bind(this), 300);

        $.flashMessage(I18n.t('The app was updated successfully'));
      };

      var error = function() {
        $.flashError(I18n.t('We were unable to update the app.'));
      };

      store.saveExternalTool(this.props.tool, data, success.bind(this), error.bind(this));
    },

    render() {
      var editAriaLabel = I18n.t('Edit %{toolName} App', { toolName: this.props.tool.attributes.name });

      return (
        <span className="EditExternalToolButton">
          <a href="#" ref="editButton" role="button" aria-label={editAriaLabel} className="edit_tool_link lm" onClick={this.openModal}>
            <i className="icon-edit btn"></i>
          </a>
          <Modal className="ReactModal__Content--external_tools" closeTimeoutMS={150} isOpen={this.state.modalIsOpen} onRequestClose={this.closeModal}>
            <div className="modal-content">
              <div className="modal-header">
                <button type="button" className="close" onClick={this.closeModal}>
                  <span aria-hidden="true">&times;</span>
                  <span className="screenreader-only">{I18n.t('Close')}</span>
                </button>
                <h4 className="modal-title">{I18n.t('Edit External Tool')}</h4>
              </div>
              <ConfigurationForm tool={this.props.tool} configurationType="manual" handleSubmit={this.saveChanges} showConfigurationSelector={false}>
                <button type="button" className="btn btn-default" onClick={this.closeModal}>{I18n.t('Cancel')}</button>
              </ConfigurationForm>
            </div>
          </Modal>
        </span>
      )
    }
  });
});
