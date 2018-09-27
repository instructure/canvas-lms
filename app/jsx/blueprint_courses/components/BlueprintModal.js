/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import I18n from 'i18n!blueprint_settings'
import React, {Component} from 'react'
import PropTypes from 'prop-types'
import cx from 'classnames'

import Modal, {ModalBody, ModalFooter} from '../../shared/components/InstuiModal'
import Button from '@instructure/ui-buttons/lib/components/Button'

export default class BlueprintModal extends Component {
  static propTypes = {
    isOpen: PropTypes.bool.isRequired,
    title: PropTypes.string,
    onCancel: PropTypes.func,
    onSave: PropTypes.func,
    children: PropTypes.element.isRequired,
    hasChanges: PropTypes.bool,
    isSaving: PropTypes.bool,
    saveButton: PropTypes.element,
    wide: PropTypes.bool
  }

  static defaultProps = {
    title: I18n.t('Blueprint'),
    hasChanges: false,
    isSaving: false,
    onSave: () => {},
    onCancel: () => {},
    saveButton: null,
    wide: false
  }

  componentDidMount() {
    this.fixBodyScroll(this.props.isOpen)
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.isOpen !== this.props.isOpen) {
      this.fixBodyScroll(nextProps.isOpen)
    }
  }

  componentDidUpdate(prevProps) {
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

  bodyOverflow = ''
  fixBodyScroll(isOpen) {
    if (isOpen) {
      this.bodyOverflow = document.body.style.overflowY
      document.body.style.overflowY = 'hidden'
    } else {
      document.body.style.overflowY = this.bodyOverflow
    }
  }

  render() {
    const classes = cx('bcs__modal-content-wrapper', {
      'bcs__modal-content-wrapper__wide': this.props.wide
    })

    return (
      <Modal
        open={this.props.isOpen}
        onDismiss={this.props.onCancel}
        onClose={this.handleModalClose}
        size="fullscreen"
        label={this.props.title}
      >
        <ModalBody>
          <div className={classes}>{this.props.children}</div>
        </ModalBody>
        <ModalFooter ref={c => (this.footer = c)}>
          {this.props.hasChanges && !this.props.isSaving ? (
            [
              <Button key="cancel" onClick={this.props.onCancel}>
                {I18n.t('Cancel')}
              </Button>,
              <span key="space">&nbsp;</span>,
              this.props.saveButton ? (
                this.props.saveButton
              ) : (
                <Button key="save" onClick={this.props.onSave} variant="primary">
                  {I18n.t('Save')}
                </Button>
              )
            ]
          ) : (
            <Button ref={c => (this.doneBtn = c)} onClick={this.props.onCancel} variant="primary">
              {I18n.t('Done')}
            </Button>
          )}
        </ModalFooter>
      </Modal>
    )
  }
}
