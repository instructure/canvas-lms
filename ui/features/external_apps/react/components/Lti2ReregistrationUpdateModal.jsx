/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import PropTypes from 'prop-types'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import store from '../lib/ExternalAppsStore'
import {Button} from '@instructure/ui-buttons'

const I18n = useI18nScope('external_tools')

export default class Lti2ReregistrationUpdateModal extends React.Component {
  static propTypes = {
    tool: PropTypes.object.isRequired,
    returnFocus: PropTypes.func.isRequired,
  }

  state = {
    modalIsOpen: false,
  }

  openModal = e => {
    e.preventDefault()
    this.setState({modalIsOpen: true})
  }

  closeModal = cb => {
    if (typeof cb === 'function') {
      this.setState({modalIsOpen: false}, cb)
    } else {
      this.setState({modalIsOpen: false})
    }
    this.props.returnFocus()
  }

  acceptUpdate = e => {
    e.preventDefault()
    this.closeModal(() => {
      store.acceptUpdate(this.props.tool)
    })
  }

  dismissUpdate = e => {
    e.preventDefault()
    this.closeModal(() => {
      store.dismissUpdate(this.props.tool)
    })
  }

  render() {
    return (
      <Modal
        open={this.state.modalIsOpen}
        onDismiss={this.closeModal}
        label={I18n.t('Update %{tool}', {tool: this.props.tool.name})}
      >
        <Modal.Body>{I18n.t('Would you like to accept or dismiss this update?')}</Modal.Body>
        <Modal.Footer>
          <Button onClick={this.closeModal}>{I18n.t('Close')}</Button>
          &nbsp;
          <Button onClick={this.dismissUpdate} color="danger">
            {I18n.t('Dismiss')}
          </Button>
          &nbsp;
          <Button onClick={this.acceptUpdate} color="primary">
            {I18n.t('Accept')}
          </Button>
        </Modal.Footer>
      </Modal>
    )
  }
}
