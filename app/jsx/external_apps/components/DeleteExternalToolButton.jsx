/** @jsx React.DOM */

define([
  'jquery',
  'i18n!external_tools',
  'react',
  'react-modal',
  'jsx/external_apps/lib/store'
], function ($, I18n, React, Modal, store) {

  var CLOSE_TIMEOUT = 150;

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
      this.setState({ modalIsOpen: true });
    },

    closeModal(cb) {
      if (typeof cb === 'function') {
        this.setState({ modalIsOpen: false }, cb);
      } else {
        this.setState({ modalIsOpen: false });
      }
    },

    deleteTool(e) {
      e.preventDefault();
      this.isDeleting = true;
      this.closeModal(() => {
        store.deleteExternalTool(this.props.tool);
        this.isDeleting = false;
      });
    },

    render() {
      return (
        <span className="DeleteExternalToolButton">
          <a href="#" role="button" aria-label={I18n.t('Delete %{toolName} App', { toolName: this.props.tool.attributes.name })} className="delete_tool_link lm" onClick={this.openModal}>
            <i className="icon-trash btn"></i>
          </a>
          <Modal className="ReactModal__Content--external_tools ReactModal__Content--confirm" closeTimeoutMS={CLOSE_TIMEOUT} isOpen={this.state.modalIsOpen} onRequestClose={this.closeModal}>
            <div className="modal-content">
              <div className="modal-header">
                <button type="button" className="close" onClick={this.closeModal}>
                  <span aria-hidden="true">&times;</span>
                  <span className="screenreader-only">{I18n.t('Close')}</span>
                </button>
                <h4 className="modal-title">{I18n.t('Delete %{tool} App?', {tool: this.props.tool.attributes.name})}</h4>
              </div>
              <div className="modal-body">
                {I18n.t('Are you sure you want to remove this tool?')}
              </div>
              <div className="modal-footer">
                <button type="button" className="btn btn-default" onClick={this.closeModal}>{I18n.t('Close')}</button>
                <button type="button" className="btn btn-danger" onClick={this.deleteTool}>{I18n.t('Delete')}</button>
              </div>
            </div>
          </Modal>
        </span>
      )
    }
  });
});
