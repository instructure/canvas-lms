import React from 'react'
import I18n from 'i18n!new_user_tutorial'
import { Button, Heading, Modal, ModalHeader, ModalBody, ModalFooter } from 'instructure-ui'
import axios from 'axios'

  class ConfirmEndTutorialDialog extends React.Component {

    static propTypes = {
      isOpen: React.PropTypes.bool,
      handleRequestClose: React.PropTypes.func.isRequired
    }

    static defaultProps = {
      isOpen: false
    }

    constructor (props) {
      super(props);
      this.appElement = document.getElementById('application');
    }

    handleModalReady = () => {
      this.appElement.setAttribute('aria-hidden', 'true');
    }

    handleModalClose = () => {
      this.appElement.removeAttribute('aria-hidden');
    }

    handleOkayButtonClick = (e, onSuccessFunc = window.location.reload) => {
      const API_URL = '/api/v1/users/self/features/flags/new_user_tutorial_on_off';
      axios.put(API_URL, {
        state: 'off'
      }).then(() => {
        // Done this way such that onSuccessFunc (reload) gets the proper thisArg
        // while still allowing us to easily provide a replacement for tests.
        onSuccessFunc.call(window.location);
      });
    }

    render () {
      return (
        <Modal
          isOpen={this.props.isOpen}
          zIndex={1000}
          onReady={this.handleModalReady}
          onClose={this.handleModalClose}
          onRequestClose={this.props.handleRequestClose}
          label={I18n.t('End Course Set-up Tutorial Dialog')}
          closeButtonLabel={I18n.t('Close')}
        >
          <ModalHeader>
            <Heading>{I18n.t('End Course Set-up Tutorial')}</Heading>
          </ModalHeader>
          <ModalBody>
            {
            I18n.t('Turning off this tutorial will remove the tutorial tray from your view ' +
                   'for all of your courses. It can be turned back on under Feature Options in your User Settings.')
          }
          </ModalBody>
          <ModalFooter>
            <Button
              onClick={this.props.handleRequestClose}
            >
              {I18n.t('Cancel')}
            </Button>
            &nbsp;
            <Button
              onClick={this.handleOkayButtonClick}
              variant="primary"
            >
              {I18n.t('Okay')}
            </Button>
          </ModalFooter>
        </Modal>
      );
    }
  }

export default ConfirmEndTutorialDialog
