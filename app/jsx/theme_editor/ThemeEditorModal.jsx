/** @jsx React.DOM */

define([
  'i18n!theme_editor',
  'react',
  'react-modal',
  'jsx/shared/ProgressBar'
], (I18n, React, Modal, ProgressBar) => {

  Modal.setAppElement(document.body)

  return React.createClass({
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
        <div className="Theme__editor_progress">
          <h4>{I18n.t('Generating Preview...')}</h4>
          <ProgressBar
            progress={this.props.progress}
            title={I18n.t('%{percent} complete', {
              percent: I18n.toPercentage(this.props.progress, {precision: 0})
            })}
          />
        </div>
      )
    },

    subAccountModalContent(){
      return (
        <div className="Theme__editor_progress">
          <h4>{I18n.t('Applying changes to subaccounts.')}</h4>
          <h5>{I18n.t('(changes will still apply if you leave this page)')}</h5>
          {this.props.activeSubAccountProgresses.map(this.subAccountProgressBar)}
        </div>
      );
    },

    subAccountProgressBar(progress){
      return (
        <div>
          <h5>{I18n.t('Progress for %{account_name}', {account_name: this.messageToName(progress.message)} )}</h5>
          <ProgressBar
            progress={progress.completion}
            title={I18n.t('Progress for %{account_name}', {
              account_name: this.messageToName(progress.message)
              })
            }
          />
        </div>
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
          className='ReactModal__Content--canvas ReactModal__Content--mini-modal'
          overlayClassName='ReactModal__Overlay--Theme__editor_progress'>
          {this.modalContent()}
        </Modal>
      )
    }
  })

})