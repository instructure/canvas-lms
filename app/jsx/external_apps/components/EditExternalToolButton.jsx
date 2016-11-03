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

  return React.createClass({
    displayName: 'EditExternalToolButton',

    propTypes: {
      tool: React.PropTypes.object.isRequired,
      canAddEdit: React.PropTypes.bool.isRequired
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
      if (this.props.canAddEdit) {
        if (this.state.tool.app_type === 'ContextExternalTool') {
          return (
            <ConfigurationForm ref="configurationForm" tool={this.state.tool} configurationType="manual" handleSubmit={this.saveChanges} showConfigurationSelector={false}>
              <button type="button" className="btn btn-default" onClick={this.closeModal}>{I18n.t('Cancel')}</button>
            </ConfigurationForm>
          );
        } else { // Lti::ToolProxy
          return <Lti2Edit ref="lti2Edit" tool={this.state.tool} handleActivateLti2={this.handleActivateLti2} handleDeactivateLti2={this.handleDeactivateLti2} handleCancel={this.closeModal} />
        }
      } else {
        return(
          <div ref="configurationForm">
            <div className="ReactModal__Body">
              <div className="formFields">
                <p>{I18n.t('This action has been disabled by your admin.')}</p>
              </div>
            </div>
            <div className="ReactModal__Footer">
              <div className="ReactModal__Footer-Actions">
                <button type="button" className="btn btn-default" onClick={this.closeModal}>{I18n.t('Cancel')}</button>
              </div>
            </div>
          </div>
        );
      }
    },

    render() {
      var editAriaLabel = I18n.t('Edit %{toolName} App', { toolName: this.state.tool.name });

      return (
        <li role="presentation" className="EditExternalToolButton">
          <a href="#" ref="editButton" tabIndex="-1" role="menuitem" aria-label={editAriaLabel} className="icon-edit" onClick={this.openModal}>
            {I18n.t('Edit')}
          </a>
          <Modal className="ReactModal__Content--canvas"
            overlayClassName="ReactModal__Overlay--canvas"
            style={modalOverrides}
            isOpen={this.state.modalIsOpen}
            onRequestClose={this.closeModal}>
            <div className="ReactModal__Layout">
              <div className="ReactModal__Header">
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
        </li>
      )
    }
  });
});
