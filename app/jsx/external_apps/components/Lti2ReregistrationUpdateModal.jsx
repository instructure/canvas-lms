define([
    'jquery',
    'i18n!external_tools',
    'react',
    'react-modal',
    'jsx/external_apps/lib/ExternalAppsStore'
], function ($, I18n, React, Modal, store) {

    return React.createClass({
        displayName: 'Lti2ReregistrationUpdateModal',

        propTypes: {
            tool: React.PropTypes.object.isRequired,
            closeHandler: React.PropTypes.func,
            canAddEdit: React.PropTypes.bool.isRequired
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

        acceptUpdate(e) {
            e.preventDefault();
            this.closeModal(() => {
                store.acceptUpdate(this.props.tool);
            });
        },

        dismissUpdate(e) {
            e.preventDefault();
            this.closeModal(() => {
                store.dismissUpdate(this.props.tool);
            });
        },

        render() {
            return(
                <Modal className="ReactModal__Content--canvas ReactModal__Content--mini-modal"
                       overlayClassName="ReactModal__Overlay--canvas"
                       isOpen={this.state.modalIsOpen}
                       onRequestClose={this.closeModal}>

                    <div className="ReactModal__Layout">
                        <div className="ReactModal__Header">
                            <div className="ReactModal__Header-Title">
                                <h4>{I18n.t('Update %{tool}', {tool: this.props.tool.name})}</h4>
                            </div>
                            <div className="ReactModal__Header-Actions">
                                <button className="Button Button--icon-action" type="button" onClick={this.closeModal}>
                                    <i className="icon-x"></i>
                                    <span className="screenreader-only">Close</span>
                                </button>
                            </div>
                        </div>

                        <div className="ReactModal__Body">
                            {I18n.t('Would you like to accept or dismiss this update?')}
                        </div>

                        <div className="ReactModal__Footer">
                            <div className="ReactModal__Footer-Actions">
                                <button ref="btnClose" type="button" className="Button" onClick={this.closeModal}>{I18n.t('Close')}</button>
                                <button ref="btnDelete" type="button" className="Button Button--danger" onClick={this.dismissUpdate}>{I18n.t('Dismiss')}</button>
                                <button ref="btnAccept" type="button" className="Button Button--primary" onClick={this.acceptUpdate}>{I18n.t('Accept')}</button>
                            </div>
                        </div>
                    </div>
                </Modal>
            )
        }

    });
});
