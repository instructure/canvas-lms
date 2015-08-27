/** @jsx React.DOM */

define([
  'jquery',
  'i18n!external_tools',
  'react',
  'react-modal'
], function ($, I18n, React, Modal) {

  return React.createClass({
    displayName: 'ConfigureExternalToolButton',

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
      this.setState({modalIsOpen: true});
    },

    closeModal(cb) {
      if (typeof cb === 'function') {
        this.setState({modalIsOpen: false}, cb);
      } else {
        this.setState({modalIsOpen: false});
      }
    },

    getLaunchUrl() {
      var toolConfigUrl = this.props.tool.tool_configuration.url;
      return ENV.CONTEXT_BASE_URL + '/external_tools/retrieve?url=' + encodeURIComponent(toolConfigUrl) + '&display=borderless';
    },

    renderIframe() {
      if (this.state.modalIsOpen) {
        return <iframe src={this.getLaunchUrl()} style={{
          width: '100%',
          padding: 0,
          margin: 0,
          height: 500,
          border: 0
        }}/>;
      } else {
        return null;
      }
    },

    render() {
      return (
        <li role="presentation" className="ConfigureExternalToolButton">
          <a href="#" tabindex="-1" ref="btnTriggerModal" role="menuitem" aria-label={I18n.t('Configure %{toolName} App', { toolName: this.props.tool.name })} className="icon-settings-2" onClick={this.openModal}>
            {I18n.t('Configure')}
          </a>
          <Modal className="ReactModal__Content--canvas"
            overlayClassName="ReactModal__Overlay--canvas"
            isOpen={this.state.modalIsOpen}
            onRequestClose={this.closeModal}>

            <div className="ReactModal__Layout">
              <div className="ReactModal__Header">
                <div className="ReactModal__Header-Title">
                  <h4>{I18n.t('Configurate %{tool} App?', {tool: this.props.tool.name})}</h4>
                </div>
                <div className="ReactModal__Header-Actions">
                  <button className="Button Button--icon-action" type="button" onClick={this.closeModal}>
                    <i className="icon-x"></i>
                    <span className="screenreader-only">Close</span>
                  </button>
                </div>
              </div>

              <div className="ReactModal__Body ReactModal__Body--force-no-padding">
                {this.renderIframe()}
              </div>

              <div className="ReactModal__Footer">
                <div className="ReactModal__Footer-Actions">
                  <button ref="btnClose" type="button" className="Button" onClick={this.closeModal}>{I18n.t('Close')}</button>
                </div>
              </div>
            </div>
          </Modal>
        </li>
      )
    }
  });
});
