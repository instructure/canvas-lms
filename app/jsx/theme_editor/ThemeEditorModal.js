import I18n from 'i18n!theme_editor'
import React from 'react'
import Modal from 'react-modal'
import ProgressBar from 'jsx/shared/ProgressBar'

  Modal.setAppElement(document.body)

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
    displayName: 'ThemeEditorModal',

    propTypes: {
      showProgressModal: React.PropTypes.bool,
      showSubAccountProgress: React.PropTypes.bool,
      progress: React.PropTypes.number,
      activeSubAccountProgresses: React.PropTypes.array,
    },

    modalOpen(){
      return this.props.showProgressModal ||
        this.props.showSubAccountProgress
    },

    modalContent(){
      if (this.props.showProgressModal) {
        return this.previewGenerationModalContent();
      } else if (this.props.showSubAccountProgress) {
        return this.subAccountModalContent();
      }
    },

    previewGenerationModalContent() {
      return (
        <div className="ReactModal__Layout">
          <header className="ReactModal__Header">
            <div className="ReactModal__Header-Title">
              <h3>{I18n.t('Generating preview...')}</h3>
            </div>
          </header>
          <div className="ReactModal__Body">
            <ProgressBar
              progress={this.props.progress}
              title={I18n.t('%{percent} complete', {
                percent: I18n.toPercentage(this.props.progress, {precision: 0})
              })}
            />
          </div>
        </div>
      )
    },

    subAccountModalContent(){
      return (
        <div className="ReactModal__Layout">
          <header className="ReactModal__Header">
            <div className="ReactModal__Header-Title">
              <h3>{I18n.t('Applying new styles to subaccounts')}</h3>
            </div>
          </header>
          <div className="ReactModal__Body">
            <p>
              {I18n.t('Changes will still apply if you leave this page.')}
            </p>
            <ul className="unstyled_list">
              {this.props.activeSubAccountProgresses.map(this.subAccountProgressBar)}
            </ul>
          </div>
        </div>
      );
    },

    subAccountProgressBar(progress){
      return (
        <li className="Theme-editor-progress-list-item">
          <div className="Theme-editor-progress-list-item__title">
            {I18n.t('%{account_name}', {account_name: this.messageToName(progress.message)} )}
          </div>
          <div className="Theme-editor-progress-list-item__bar">
            <ProgressBar
              progress={progress.completion}
              title={I18n.t('Progress for %{account_name}', {
                account_name: this.messageToName(progress.message)
                })
              }
            />
          </div>
        </li>
      );
    },

    messageToName(message){
      return message.indexOf("Syncing for") > -1 ?
        message.replace("Syncing for ", "") :
        I18n.t("Unknown Account")
    },

    render() {
      return (
        <Modal
          isOpen={this.modalOpen()}
          className={ 
            (this.props.showProgressModal ? 'ReactModal__Content--canvas ReactModal__Content--mini-modal' : 'ReactModal__Content--canvas') 
          }
          style={modalOverrides}
        >
          {this.modalContent()}
        </Modal>
      )
    }
  })
