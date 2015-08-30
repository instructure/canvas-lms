/** @jsx React.DOM */

define([
  'jquery',
  'i18n!external_tools',
  'react',
  'react-modal',
  'jsx/external_apps/lib/ExternalAppsStore'
], function ($, I18n, React, Modal, store) {

  return React.createClass({
    displayName: 'DeleteExternalToolButton',

    isDeleting: false,

    shouldComponentUpdate() {
      return !this.isDeleting;
    },

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

    deleteTool(e) {
      e.preventDefault();
      this.isDeleting = true;
      this.closeModal(() => {
        store.delete(this.props.tool);
        this.isDeleting = false;
      });
    },

    render() {
      return (
        <li role="presentation" className="DeleteExternalToolButton">
          <a href="#" tabindex="-1" ref="btnTriggerDelete" role="button" aria-label={I18n.t('Delete %{toolName} App', { toolName: this.props.tool.name })} className="icon-trash" onClick={this.openModal}>
            {I18n.t('Delete')}
          </a>
          <Modal className="ReactModal__Content--canvas ReactModal__Content--mini-modal"
            overlayClassName="ReactModal__Overlay--canvas"
            isOpen={this.state.modalIsOpen}
            onRequestClose={this.closeModal}>

            <div className="ReactModal__Layout">

              <div className="ReactModal__Header">
                <div className="ReactModal__Header-Title">
                  <h4>{I18n.t('Delete %{tool} App?', {tool: this.props.tool.name})}</h4>
                </div>
                <div className="ReactModal__Header-Actions">
                  <button className="Button Button--icon-action" type="button" onClick={this.closeModal}>
                    <i className="icon-x"></i>
                    <span className="screenreader-only">Close</span>
                  </button>
                </div>
              </div>

              <div className="ReactModal__Body">
                {I18n.t('Are you sure you want to remove this tool?')}
              </div>

              <div className="ReactModal__Footer">
                <div className="ReactModal__Footer-Actions">
                  <button ref="btnClose" type="button" className="Button" onClick={this.closeModal}>{I18n.t('Close')}</button>
                  <button ref="btnDelete" type="button" className="Button Button--danger" onClick={this.deleteTool}>{I18n.t('Delete')}</button>
                </div>
              </div>
            </div>
          </Modal>
        </li>
      )
    }
  });
});
