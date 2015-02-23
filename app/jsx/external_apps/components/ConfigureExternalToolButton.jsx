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
        <span className="ConfigureExternalToolButton">
          <a href="#" ref="btnTriggerModal" role="button" aria-label={I18n.t('Configure %{toolName} App', { toolName: this.props.tool.name })} className="lm" onClick={this.openModal}>
            <i className="icon-settings btn"></i>
          </a>
          <Modal className="ReactModal__Content--canvas"
            overlayClassName="ReactModal__Overlay--canvas"
            isOpen={this.state.modalIsOpen}
            onRequestClose={this.closeModal}>

            <div className="ReactModal__Layout">

              <div className="ReactModal__InnerSection ReactModal__Header ReactModal__Header--force-no-corners">
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

              <div className="ReactModal__InnerSection ReactModal__Body ReactModal__Body--force-no-padding">
                {this.renderIframe()}
              </div>

              <div className="ReactModal__InnerSection ReactModal__Footer">
                <div className="ReactModal__Footer-Actions">
                  <button ref="btnClose" type="button" className="btn btn-default" onClick={this.closeModal}>{I18n.t('Close')}</button>
                </div>
              </div>
            </div>
          </Modal>
        </span>
      )
    }
  });
});
