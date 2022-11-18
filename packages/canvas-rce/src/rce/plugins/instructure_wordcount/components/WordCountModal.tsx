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

// Doing this to avoid TS2339 errors -- TODO: remove once we're on InstUI 8
const {Head, Row, ColHeader, Body, Cell} = Table as any

const renderBody = (headers: Header[], rows: CountRow[]) => {
  return (
    <Table caption={formatMessage('Word Count')}>
      <Head>
        <Row>
          {headers.map(({id, label}) => (
            <ColHeader key={id} id={id}>
              {label}
            </ColHeader>
          ))}
        </Row>
      </Head>
      <Body>
        {rows.map(({label, documentCount, selectionCount}) => (
          <Row key={label}>
            <Cell key="label">{label}</Cell>
            <Cell key="document">{documentCount}</Cell>
            <Cell key="selection">{selectionCount}</Cell>
          </Row>
        ))}
      </Body>
    </Table>
  )
}

export type WordCountModalProps = {
  readonly headers: Header[]
  readonly rows: CountRow[]
  readonly onDismiss: () => void
}

export const WordCountModal: React.FC<WordCountModalProps> = ({headers, rows, onDismiss}) => {
  return (
    <Modal label={formatMessage('Word Count')} open={true} data-mce-component={true}>
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
