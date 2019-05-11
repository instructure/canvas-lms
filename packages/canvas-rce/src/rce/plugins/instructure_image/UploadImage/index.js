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

import React from 'react'
import {func} from 'prop-types'
import {Modal, ModalHeader, ModalBody, ModalFooter} from '@instructure/ui-overlays'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-elements'
import {Tabs} from '@instructure/ui-tabs'
import formatMessage from '../../../../format-message'

export function UploadImage(props) {
  return (
    <Modal
      as="form"
      label={formatMessage('Upload Image')}
      size="large"
      onDismiss={props.onDismiss}
      onSubmit={() => {}}
      open
      shouldCloseOnDocumentClick
    >
      <ModalHeader>
        <CloseButton onClick={props.onDismiss} offset="none" placement="end">
          {formatMessage('Close')}
        </CloseButton>
        <Heading>{formatMessage('Upload Image')}</Heading>
      </ModalHeader>
      <ModalBody>
        <Tabs defaultSelectedIndex={0}>
          <Tabs.Panel title={formatMessage('Computer')}>Computer Panel Here</Tabs.Panel>
          <Tabs.Panel title={formatMessage('Unsplash')}>Unsplash Panel Here</Tabs.Panel>
          <Tabs.Panel title={formatMessage('URL')}>URL Panel Here</Tabs.Panel>
        </Tabs>
      </ModalBody>
      <ModalFooter>
        <Button onClick={props.onDismiss}>{formatMessage('Close')}</Button>&nbsp;
        <Button variant="primary" type="submit">
          {formatMessage('Submit')}
        </Button>
      </ModalFooter>
    </Modal>
  )
}

UploadImage.propTypes = {
  onDismiss: func.isRequired
}
