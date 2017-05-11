import React from 'react';
import Button from 'instructure-ui/lib/components/Button';
import Modal, { ModalBody, ModalFooter, ModalHeader } from 'instructure-ui/lib/components/Modal';
import Heading from 'instructure-ui/lib/components/Heading';
import TabList, { TabPanel } from 'instructure-ui/lib/components/TabList';
import I18n from 'i18n!gradebook';

const { func } = React.PropTypes;

class GradebookSettingsModal extends React.Component {
  static propTypes = {
    onClose: func.isRequired
  }

  constructor (props) {
    super(props);
    this.state = { isOpen: false };
    this.open = this.open.bind(this);
    this.close = this.close.bind(this);
  }

  open () {
    this.setState({ isOpen: true });
  }

  close () {
    this.setState({ isOpen: false });
    this.props.onClose();
  }

  render () {
    const title = I18n.t('Gradebook Settings');
    const { onClose } = this.props;
    const { isOpen } = this.state;

    return (
      <Modal
        isOpen={isOpen}
        label={title}
        closeButtonLabel={I18n.t('Close')}
        onRequestClose={this.close}
        onExited={onClose}
      >
        <ModalHeader>
          <Heading level="h3">{ I18n.t('Gradebook Settings') }</Heading>
        </ModalHeader>
        <ModalBody>
          <TabList defaultSelectedIndex={0}>
            <TabPanel id="late-policies-tab" title={I18n.t('Late Policies')}>
              <p>Late policy options go here</p>
            </TabPanel>
          </TabList>
        </ModalBody>
        <ModalFooter>
          <Button
            id="gradebook-settings-cancel-button"
            onClick={this.close} margin="small"
          >
            {I18n.t('Cancel')}
          </Button>

          &nbsp;

          <Button
            id="gradebook-settings-update-button"
            variant="primary"
            margin="small"
          >
            {I18n.t('Update')}
          </Button>
        </ModalFooter>
      </Modal>
    );
  }
}

export default GradebookSettingsModal;
