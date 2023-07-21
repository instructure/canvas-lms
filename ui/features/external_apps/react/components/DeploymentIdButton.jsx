/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {Button} from '@instructure/ui-buttons'
import Modal from '@canvas/instui-bindings/react/InstuiModal'

const I18n = useI18nScope('external_tools')

export default class DeploymentIdButton extends React.Component {
  static propTypes = {
    tool: PropTypes.shape({name: PropTypes.string, deployment_id: PropTypes.string}).isRequired,
    returnFocus: PropTypes.func.isRequired,
  }

  state = {
    modalIsOpen: false,
  }

  openModal = e => {
    e.preventDefault()
    this.setState({modalIsOpen: true})
  }

  closeModal = () => {
    this.setState({modalIsOpen: false})
    this.props.returnFocus()
  }

  render() {
    return (
      <li role="presentation" className="ui-menu-item">
        {/* TODO: use InstUI button */}
        {/* eslint-disable-next-line jsx-a11y/anchor-is-valid */}
        <a
          href="#"
          tabIndex="-1"
          role="button"
          aria-label={I18n.t('Deployment id for %{toolName} App', {toolName: this.props.tool.name})}
          className="icon-lti"
          onClick={this.openModal}
        >
          {I18n.t('Deployment Id')}
        </a>
        <Modal
          open={this.state.modalIsOpen}
          onDismiss={this.closeModal}
          label={I18n.t('Deployment Id for %{tool} App', {tool: this.props.tool.name})}
        >
          <Modal.Body>{this.props.tool.deployment_id}</Modal.Body>
          <Modal.Footer>
            <Button onClick={this.closeModal}>{I18n.t('Close')}</Button>
          </Modal.Footer>
        </Modal>
      </li>
    )
  }
}
