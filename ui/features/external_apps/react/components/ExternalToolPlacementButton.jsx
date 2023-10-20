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
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import ExternalToolPlacementList from './ExternalToolPlacementList'

const I18n = useI18nScope('external_tools')

export default class ExternalToolPlacementButton extends React.Component {
  static propTypes = {
    tool: PropTypes.object.isRequired,
    type: PropTypes.string, // specify "button" if this is not a menu item
    returnFocus: PropTypes.func.isRequired,
    onToggleSuccess: PropTypes.func.isRequired,
  }

  state = {
    tool: this.props.tool,
    modalIsOpen: false,
    isRetrievingTool: false,
  }

  openModal = e => {
    e.preventDefault()

    // Don't open the modal if it's already open
    if (this.state.modalIsOpen) {
      return
    }

    this.setState({
      isRetrievingTool: true,
      modalIsOpen: true,
    })

    store.fetchWithDetails(this.props.tool).then(data => {
      this.setState({
        tool: {...data, ...this.props.tool},
        isRetrievingTool: false,
      })
    })
  }

  closeModal = () => {
    this.setState({modalIsOpen: false})
    this.props.returnFocus()
  }

  spinner = () => (
    <Flex justifyItems="center">
      <Flex.Item>
        <Spinner renderTitle={() => I18n.t('Retrieving Tool')} />
      </Flex.Item>
    </Flex>
  )

  modal = () => (
    <Modal
      open={this.state.modalIsOpen}
      onDismiss={this.closeModal}
      label={I18n.t('App Placements')}
    >
      <Modal.Body>
        {this.state.isRetrievingTool ? (
          this.spinner()
        ) : (
          <ExternalToolPlacementList
            tool={this.state.tool}
            onToggleSuccess={this.props.onToggleSuccess}
          />
        )}
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={this.closeModal}>{I18n.t('Close')}</Button>
      </Modal.Footer>
    </Modal>
  )

  button = () => {
    const editAriaLabel = I18n.t('View %{toolName} Placements', {toolName: this.state.tool.name})

    if (this.props.type === 'button') {
      return (
        <>
          {/* eslint-disable-next-line jsx-a11y/anchor-is-valid */}
          <a
            href="#"
            role="button"
            aria-label={editAriaLabel}
            className="btn long"
            onClick={this.openModal}
          >
            <i className="icon-info" data-tooltip="left" title={I18n.t('Tool Placements')} />
            {this.modal()}
          </a>
        </>
      )
    } else {
      return (
        <li role="presentation" className="ExternalToolPlacementButton">
          {/* eslint-disable-next-line jsx-a11y/anchor-is-valid */}
          <a
            href="#"
            tabIndex="-1"
            role="menuitem"
            aria-label={editAriaLabel}
            className="icon-info"
            onClick={this.openModal}
          >
            {I18n.t('Placements')}
          </a>
          {this.modal()}
        </li>
      )
    }
  }

  render() {
    if (this.state.tool.app_type === 'ContextExternalTool') {
      return this.button()
    }
    return false
  }
}
