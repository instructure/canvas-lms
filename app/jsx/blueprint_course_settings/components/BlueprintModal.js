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
    hasChanges: PropTypes.bool,
    isSaving: PropTypes.bool,
  }

  static defaultProps = {
    title: I18n.t('Blueprint'),
    isSaving: false,
    hasChanges: false,
    onSave: () => {},
    onCancel: () => {},
  }

  componentDidUpdate (prevProps) {
    // if just started saving, then the save button was just clicked
    // and it is about to disappear, so focus on the done button
    // that replaces it
    if (!prevProps.isSaving && this.props.isSaving) {
      // set timeout so we queue this after the render, to ensure done button is mounted
      setTimeout(() => {
        this.doneBtn.focus()
      }, 0)
    }
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
        <ModalFooter ref={(c) => { this.footer = c }}>
          {this.props.hasChanges && !this.props.isSaving ? (
            <span>
              <Button onClick={this.props.onCancel}>{I18n.t('Cancel')}</Button>&nbsp;
              <Button onClick={this.props.onSave} variant="primary">{I18n.t('Save')}</Button>
            </span>
          ) : (
            <Button ref={(c) => { this.doneBtn = c }} onClick={this.props.onCancel} variant="primary">{I18n.t('Done')}</Button>
          )}
        </ModalFooter>
      </Modal>
    )
  }
}
