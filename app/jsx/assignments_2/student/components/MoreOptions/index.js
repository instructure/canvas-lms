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

import ExternalToolsQuery from './ExternalToolsQuery'
import I18n from 'i18n!assignments_2_initial_query'
import React from 'react'
import {string} from 'prop-types'

import Button from '@instructure/ui-buttons/lib/components/Button'
import CloseButton from '@instructure/ui-buttons/lib/components/CloseButton'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import Modal, {
  ModalHeader,
  ModalBody,
  ModalFooter
} from '@instructure/ui-overlays/lib/components/Modal'

class MoreOptions extends React.Component {
  state = {
    open: false
  }

  _isMounted = false

  componentDidMount() {
    this._isMounted = true
    window.addEventListener('message', this.handleIframeTask)
  }

  componentWillUnmount() {
    this._isMounted = false
  }

  handleIframeTask = async e => {
    if (e.data.messageType === 'LtiDeepLinkingResponse') {
      if (this._isMounted) {
        this.setState({open: false})
      }
    }
  }

  handleModalOpen = () => {
    if (this._isMounted) {
      this.setState({open: true})
    }
  }

  handleModalClose = () => {
    if (this._isMounted) {
      this.setState({open: false})
    }
  }

  renderCloseButton = () => (
    <CloseButton placement="end" offset="medium" variant="icon" onClick={this.handleModalClose}>
      {I18n.t('Close')}
    </CloseButton>
  )

  render() {
    return (
      <React.Fragment>
        <div style={{display: 'block'}}>
          <Button
            data-testid="more-options-button"
            onClick={this.handleModalOpen}
            margin="medium 0"
          >
            {I18n.t('More Options')}
          </Button>
        </div>
        <Modal
          as="form"
          data-testid="more-options-modal"
          open={this.state.open}
          onDismiss={this.handleModalClose}
          size="large"
          label="More Options"
          shouldCloseOnDocumentClick
        >
          <ModalHeader>
            {this.renderCloseButton()}
            <Heading>{I18n.t('More Options')}</Heading>
          </ModalHeader>
          <ModalBody padding="0 small">
            <ExternalToolsQuery
              assignmentID={this.props.assignmentID}
              courseID={this.props.courseID}
            />
          </ModalBody>
          <ModalFooter>
            <Button onClick={this.handleModalClose} margin="0 xx-small 0 0">
              {I18n.t('Cancel')}
            </Button>
            <Button variant="primary" type="submit">
              {I18n.t('Upload')}
            </Button>
          </ModalFooter>
        </Modal>
      </React.Fragment>
    )
  }
}
MoreOptions.propTypes = {
  assignmentID: string.isRequired,
  courseID: string.isRequired
}

export default MoreOptions
