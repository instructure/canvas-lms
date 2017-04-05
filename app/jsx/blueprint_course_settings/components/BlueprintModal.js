import I18n from 'i18n!blueprint_settings'
import React, { Component, PropTypes } from 'react'
import Modal, { ModalHeader, ModalBody, ModalFooter } from 'instructure-ui/lib/components/Modal'
import Heading from 'instructure-ui/lib/components/Heading'
import Button from 'instructure-ui/lib/components/Button'

export default class BlueprintModal extends Component {
  static propTypes = {
    isOpen: PropTypes.bool.isRequired,
    title: PropTypes.string,
    onCancel: PropTypes.func,
    onSave: PropTypes.func,
    children: PropTypes.func.isRequired,
  }

  static defaultProps = {
    title: I18n.t('Blueprint'),
    onSave: () => {},
    onCancel: () => {},
  }

  render () {
    return (
      <Modal
        isOpen={this.props.isOpen}
        onRequestClose={this.props.onCancel}
        onClose={this.handleModalClose}
        transition="fade"
        size="fullscreen"
        label={this.props.title}
        closeButtonLabel={I18n.t('Close')}
      >
        <ModalHeader>
          <Heading level="h3">{this.props.title}</Heading>
        </ModalHeader>
        <ModalBody>
          {this.props.children()}
        </ModalBody>
        <ModalFooter>
          <Button onClick={this.props.onCancel}>{I18n.t('Cancel')}</Button>&nbsp;
          <Button onClick={this.props.onSave} variant="primary">{I18n.t('Save')}</Button>
        </ModalFooter>
      </Modal>
    )
  }
}
