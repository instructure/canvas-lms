/** @jsx React.DOM */

define([
  'jquery',
  'underscore',
  'i18n!external_tools',
  'react',
  'react-modal',
  'jsx/external_apps/lib/ExternalAppsStore',
  'jsx/external_apps/components/ConfigurationForm',
  'jsx/external_apps/components/Lti2Edit',
  'compiled/jquery.rails_flash_notifications'
], function ($, _, I18n, React, Modal, store, ConfigurationForm, Lti2Edit) {

  return React.createClass({
    displayName: 'EditExternalToolButton',

    propTypes: {
      tool: React.PropTypes.object.isRequired
    },

    getInitialState() {
      return {
        tool: this.props.tool,
        modalIsOpen: false
      }
    },

    openModal(e) {
      e.preventDefault();
      if (this.props.tool.app_type === 'ContextExternalTool') {
        store.fetchWithDetails(this.props.tool).then(function(data) {
          var tool = _.extend(data, this.props.tool);
          this.setState({
            tool: tool,
            modalIsOpen: true
          });
        }.bind(this));
      } else {
        this.setState({
          tool: this.props.tool,
          modalIsOpen: true
        });
      }
    },

    closeModal() {
      this.setState({ modalIsOpen: false });
    },

    saveChanges(configurationType, data) {
      var success = function(response) {
        var updatedTool = _.extend(this.state.tool, response);

        if (this.state.tool.name !== this.props.tool.name) {
          store.fetch();
        } else {
          this.setState({ tool: updatedTool });
        }
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

      var tool = _.extend(this.state.tool, data);
      store.save(configurationType, tool, success.bind(this), error.bind(this));
    },

    handleActivateLti2() {
      store.activate(this.state.tool,
        function() {
          this.closeModal();
          $.flashMessage(I18n.t('The app was activated'));
        }.bind(this),
        function() {
          this.closeModal();
          $.flashError(I18n.t('We were unable to activate the app.'));
        }.bind(this)
      );
    },

    handleDeactivateLti2() {
      store.deactivate(this.state.tool,
        function() {
          this.closeModal();
          $.flashMessage(I18n.t('The app was deactivated'));
        }.bind(this),
        function() {
          this.closeModal();
          $.flashError(I18n.t('We were unable to deactivate the app.'));
        }.bind(this)
      );
    },

    form() {
      if (this.state.tool.app_type === 'ContextExternalTool') {
        return (
          <ConfigurationForm ref="configurationForm" tool={this.state.tool} configurationType="manual" handleSubmit={this.saveChanges} showConfigurationSelector={false}>
            <button type="button" className="btn btn-default" onClick={this.closeModal}>{I18n.t('Cancel')}</button>
          </ConfigurationForm>
        );
      } else { // Lti::ToolProxy
        return <Lti2Edit ref="lti2Edit" tool={this.state.tool} handleActivateLti2={this.handleActivateLti2} handleDeactivateLti2={this.handleDeactivateLti2} handleCancel={this.closeModal} />
      }
    },

    render() {
      var editAriaLabel = I18n.t('Edit %{toolName} App', { toolName: this.state.tool.name });

      return (
        <span className="EditExternalToolButton">
          <a href="#" ref="editButton" role="button" aria-label={editAriaLabel} className="edit_tool_link lm" onClick={this.openModal}>
            <i className="icon-edit btn"></i>
          </a>
          <Modal className="ReactModal__Content--canvas"
            overlayClassName="ReactModal__Overlay--canvas"
            isOpen={this.state.modalIsOpen}
            onRequestClose={this.closeModal}>

            <div className="ReactModal__Layout">

              <div className="ReactModal__InnerSection ReactModal__Header ReactModal__Header--force-no-corners">
                <div className="ReactModal__Header-Title">
                  <h4>{I18n.t('Edit App')}</h4>
                </div>
                <div className="ReactModal__Header-Actions">
                  <button className="Button Button--icon-action" type="button" onClick={this.closeModal}>
                    <i className="icon-x"></i>
                    <span className="screenreader-only">Close</span>
                  </button>
                </div>
              </div>

              {this.form()}
            </div>
          </Modal>
        </span>
      )
    }
  });
});
