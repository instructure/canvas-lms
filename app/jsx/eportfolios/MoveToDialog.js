/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import React from 'react'
import PropTypes from 'prop-types'
import $ from 'jquery'
import I18n from 'i18n!eportfolio'
import Modal, {ModalHeader, ModalBody, ModalFooter } from 'instructure-ui/lib/components/Modal'
import Button from 'instructure-ui/lib/components/Button'
import Heading from 'instructure-ui/lib/components/Heading'
import Select from 'instructure-ui/lib/components/Select'

  var MoveToDialog = React.createClass({
    propTypes: {
      header: PropTypes.string.isRequired,
      source: PropTypes.object.isRequired,
      destinations: PropTypes.arrayOf(PropTypes.object).isRequired,
      onMove: PropTypes.func,
      onClose: PropTypes.func,
      appElement: PropTypes.object,
      triggerElement: PropTypes.object
    },

    getInitialState () {
      return {
        isOpen: true
      };
    },

    handleMove() {
      if (this.props.onMove) {
        this.props.onMove(this.refs.select.value)
      }
      this.handleRequestClose()
    },

    handleRequestClose() {
      this.setState({ isOpen: false })
    },

    handleClose() {
      if (this.props.appElement) {
        this.props.appElement.removeAttribute('aria-hidden')
      }
      if (this.props.triggerElement) {
        this.props.triggerElement.focus()
      }
      if (this.props.onClose) {
        this.props.onClose()
      }
    },

    handleReady() {
      if (this.props.appElement) {
        this.props.appElement.setAttribute('aria-hidden', true)
      }
    },

    renderBody() {
      const selectLabel = I18n.t('Place "%{section}" before:', {
        section: this.props.source.label
      })

      return (
        <div>
          <Select id='MoveToDialog__select' ref='select' label={selectLabel}>
          {
            this.props.destinations.map((dest) => (
              <option key={dest.id} value={dest.id}>{ dest.label }</option>
            ))
          }
            <option key='move-to-dialog_at-the-bottom' value=''>{ I18n.t('-- At the bottom --') }</option>
          </Select>
        </div>
      )
    },

    render() {
      const dialogLabel = I18n.t('Modal dialog: %{header} %{source}', {
        header: this.props.header,
        source: this.props.source.label
      })
      return (
        <Modal ref='modal' isOpen={this.state.isOpen}
          modalSize='small'
          label={dialogLabel}
          closeButtonLabel={I18n.t('Cancel')}
          onReady={this.handleReady}
          onRequestClose={this.handleRequestClose}
          onClose={this.handleClose}
        >
          <ModalHeader>
            <Heading>{ this.props.header }</Heading>
          </ModalHeader>
          <ModalBody>
            { this.renderBody() }
          </ModalBody>
          <ModalFooter>
            <Button id='MoveToDialog__cancel' onClick={this.handleRequestClose}>{I18n.t('Cancel')}</Button>
            <Button id='MoveToDialog__move' variant='primary' onClick={this.handleMove}>{I18n.t('Move')}</Button>
          </ModalFooter>
        </Modal>
      )
    }
  });
export default MoveToDialog
