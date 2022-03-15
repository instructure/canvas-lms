/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'

interface PassedProps {
  readonly open: boolean
  readonly onDismiss: () => any
  readonly confirm: () => any
}

class UpdateExistingPacesModal extends React.PureComponent<PassedProps> {
  render() {
    return (
      <Modal
        open={this.props.open}
        onDismiss={this.props.onDismiss}
        label="Update Existing Paces"
        shouldCloseOnDocumentClick
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="medium"
            onClick={this.props.onDismiss}
            screenReaderLabel="Close"
          />
          <Heading>Update Existing Paces?</Heading>
        </Modal.Header>

        <Modal.Body>
          <View as="div" width="36rem">
            Would you like to re-publish paces with the blackout dates you have specified?
            Assignment due dates may be changed.
          </View>
        </Modal.Body>

        <Modal.Footer>
          <Button color="secondary" onClick={this.props.onDismiss}>
            No
          </Button>
          &nbsp;
          <Button color="primary" onClick={this.props.confirm}>
            Yes
          </Button>
        </Modal.Footer>
      </Modal>
    )
  }
}

export default UpdateExistingPacesModal
