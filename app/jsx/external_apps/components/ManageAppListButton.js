import I18n from 'i18n!external_tools'
import React from 'react'
import Modal from 'react-modal'
import ConfigOptionField from 'jsx/external_apps/components/ConfigOptionField'

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

export default React.createClass({
    displayName: 'ManageAppListButton',

    propTypes: {
      onUpdateAccessToken: React.PropTypes.func.isRequired,
      extAppStore: React.PropTypes.object
    },

    getInitialState() {
      return {
        modalIsOpen: false,
        accessToken: undefined
      };
    },
    componentDidMount() {
      this.setState({originalAccessToken: this.maskedAccessToken(ENV.MASKED_APP_CENTER_ACCESS_TOKEN), accessToken: this.maskedAccessToken(ENV.MASKED_APP_CENTER_ACCESS_TOKEN)});
    },
    closeModal(cb) {
      if (typeof cb === 'function') {
        this.setState({modalIsOpen: false}, cb);
      } else {
        this.setState({modalIsOpen: false});
      }
    },
    openModal() {
      this.setState({ modalIsOpen: true, accessToken: this.state.originalAccessToken });
    },
    successHandler() {
      this.setState({ originalAccessToken: this.maskedAccessToken(this.state.accessToken.substring(0, 5)) });
      if (typeof this.props.onUpdateAccessToken === 'function') {
        this.props.onUpdateAccessToken();
      }
    },
    errorHandler() {
      $.flashError(I18n.t('We were unable to add the access token.'));
    },
    handleChange(e) {
      this.setState({ accessToken: e.target.value });
    },
    handleSubmit() {
      this.closeModal(() => {
        if(this.state.accessToken != this.state.originalAccessToken) {
          this.props.extAppStore.updateAccessToken(ENV.CONTEXT_BASE_URL, this.state.accessToken, this.successHandler, this.errorHandler);
        };
      });
    },
    maskedAccessToken(token) {
      if(typeof(token) === 'string') {
        return token + '...';
      };
    },
    render() {
      return (
        <button className="btn lm" onClick={this.openModal}>
          {I18n.t('Manage App List')}
          <Modal className="ReactModal__Content--canvas"
            overlayClassName="ReactModal__Overlay--canvas"
            isOpen={this.state.modalIsOpen}
            onRequestClose={this.closeModal}
            style={modalOverrides}>

            <div className="ReactModal__Layout">

              <div className="ReactModal__Header">
                <div className="ReactModal__Header-Title">
                  <h4 id="modalHeader">{I18n.t('Manage App List')}</h4>
                </div>
                <div className="ReactModal__Header-Actions">
                  <button className="Button Button--icon-action" type="button" onClick={this.closeModal}>
                    <i className="icon-x"></i>
                    <span className="screenreader-only">{I18n.t('Close')}</span>
                  </button>
                </div>
              </div>

              <div className="ReactModal__Body">
                <p  dangerouslySetInnerHTML={{
                    __html:
                      I18n.t('Enter the access token for your organization from \
                        *eduappcenter.com*. Once applied, only apps your organization has approved in the \
                        EduAppCenter will be listed on the External Apps page. \
                        Learn how to **generate an access token**.', {
                          wrappers: [
                            '<a href="https://www.eduappcenter.com">$1</a>',
                            '<a href="https://community.canvaslms.com/docs/DOC-3026">$1</a>'
                          ]
                      })
                    }}
                  />
                <form role="form">
                  <ConfigOptionField name="manage_app_list_token"
                    type="text"
                    description={I18n.t('Access Token')}
                    value={this.state.accessToken}
                    handleChange={this.handleChange} />
                </form>
              </div>

              <div className="ReactModal__Footer">
                <div className="ReactModal__Footer-Actions">
                  <button type="button" ref="btnClose" className="btn btn-default" onClick={this.closeModal}>{I18n.t('Cancel')}</button>
                  <button type="button" ref="btnUpdateAccessToken" className="btn btn-primary" onClick={this.handleSubmit}>{I18n.t('Save')}</button>
                </div>
              </div>
            </div>

          </Modal>
        </button>
      );
    }
  });
