define([
  'jquery',
  'underscore',
  'i18n!external_tools',
  'react',
  'react-modal',
  'jsx/external_apps/components/Lti2Iframe',
  'jsx/external_apps/components/Lti2ReregistrationUpdateModal',
  'jsx/external_apps/lib/ExternalAppsStore',
  'compiled/jquery.rails_flash_notifications'
], function ($, _, I18n, React, ReactModal, Lti2Iframe, Lti2ReregistrationUpdateModal, store) {

  return React.createClass({
    displayName: 'ReregisterExternalToolButton',

    componentDidUpdate: function () {
      var _this = this;
      window.requestAnimationFrame(function () {
        var node = document.getElementById('close' + _this.state.tool.name);
        if (node) {
          node.focus();
        }
      });
    },

    getInitialState() {
      return {
        tool: this.props.tool,
        modalIsOpen: false,
        registrationUpdateModalIsOpen: false
      }
    },

    openModal(e) {
      e.preventDefault();
      this.setState({
        tool: this.props.tool,
        modalIsOpen: true
      });
    },

    closeModal() {
      this.setState({modalIsOpen: false});
    },

    handleReregistration(_message, e) {
      this.props.tool.has_update = true;
      store.triggerUpdate();
      this.closeModal();
      this.refs.reregModal.openModal(e)
    },

    reregistrationUpdateCloseHandler() {
      this.setState({reregistrationUpdateModalIsOpen: false})
    },

    getModal() {
      return (
          <ReactModal
              ref='reactModal'
              isOpen={this.state.modalIsOpen}
              onRequestClose={this.closeModal}
              className='ReactModal__Content--canvas'
              overlayClassName='ReactModal__Overlay--canvas'
          >
            <div id={this.state.tool.name + "Heading"}
                 className="ReactModal__Layout"
            >
              <div className="ReactModal__Header">
                <div className="ReactModal__Header-Title">
                  <h4 tabindex="-1">{I18n.t('App Reregistration')}</h4>
                </div>
                <div className="ReactModal__Header-Actions">
                  <button className="Button Button--icon-action" ref="btnClose" type="button" onClick={this.closeModal}>
                    <i className="icon-x"></i>
                    <span className="screenreader-only">Close</span>
                  </button>
                </div>
              </div>
              <div tabindex="-1" className="ReactModal__Body">
                <Lti2Iframe ref="lti2Iframe" handleInstall={this.handleReregistration}
                            registrationUrl={this.props.tool.reregistration_url} reregistration={true}/>
              </div>
            </div>
          </ReactModal>
      );
    },

    getButton() {
      var editAriaLabel = I18n.t('Reregister %{toolName}', {toolName: this.state.tool.name});
      return (

          <a href="#" tabIndex="-1" ref="reregisterExternalToolButton" role="menuitem" aria-label={editAriaLabel}
             className="icon-refresh" onClick={this.openModal}>
            {I18n.t('Reregister')}
          </a>

      );

    },


    render() {
      if (this.props.tool.reregistration_url) {
        return (
            <li role="presentation" className="ReregisterExternalToolButton">
              { this.getButton() }
              { this.getModal() }
              <Lti2ReregistrationUpdateModal tool={this.props.tool}
                                             ref="reregModal"/>
            </li>
        );
      }
      return false;
    }

  });
});
