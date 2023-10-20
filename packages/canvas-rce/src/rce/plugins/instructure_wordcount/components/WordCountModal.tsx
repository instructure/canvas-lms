// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {BaseButton, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Table} from '@instructure/ui-table'
import formatMessage from '../../../../format-message'
import {Header, CountRow} from '../utils/tableContent'
import {instuiPopupMountNode} from '../../../../util/fullscreenHelpers'

const renderBody = (headers: Header[], rows: CountRow[]) => {
  return (
    <Table caption={formatMessage('Word Count')}>
      <Table.Head>
        <Table.Row>
          {headers.map(({id, getLabel}) => (
            <Table.ColHeader key={id} id={id}>
              {getLabel()}
            </Table.ColHeader>
          ))}
        </Table.Row>
      </Table.Head>
      <Table.Body>
        {rows.map(({label, documentCount, selectionCount}) => (
          <Table.Row key={label}>
            <Table.Cell key="label">{label}</Table.Cell>
            <Table.Cell key="document">{documentCount}</Table.Cell>
            <Table.Cell key="selection">{selectionCount}</Table.Cell>
          </Table.Row>
        ))}
      </Table.Body>
    </Table>
  )
}

export type WordCountModalProps = {
  readonly headers: Header[]
  readonly rows: CountRow[]
  readonly onDismiss: () => void
}

export const WordCountModal = ({headers, rows, onDismiss}: WordCountModalProps) => {
  return (
    <Modal
      label={formatMessage('Word Count')}
      mountNode={instuiPopupMountNode}
      open={true}
      data-mce-component={true}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="medium"
          color="primary"
          onClick={onDismiss}
          screenReaderLabel={formatMessage('Close')}
        />
        <Heading>{formatMessage('Word Count')}</Heading>
      </Modal.Header>
      <Modal.Body padding="x-large">{renderBody(headers, rows)}</Modal.Body>
      <Modal.Footer>
        <BaseButton onClick={onDismiss} data-testid="footer-close-button" color="primary">
          {formatMessage('Close')}
        </BaseButton>
      </Modal.Footer>
    </Modal>
  )
}
