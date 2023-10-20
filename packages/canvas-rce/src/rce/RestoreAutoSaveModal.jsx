/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import React, {useState} from 'react'
import {bool, func, string} from 'prop-types'
import {Alert} from '@instructure/ui-alerts'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {ToggleGroup} from '@instructure/ui-toggle-details'
import {View} from '@instructure/ui-view'
import formatMessage from '../format-message'

export default function RestoreAutoSaveModal(props) {
  const [previewExpanded, setPreviewExpanded] = useState(false)

  const toggleLabel = () =>
    previewExpanded
      ? formatMessage('Click to hide preview')
      : formatMessage('Click to show preview')

  return (
    <Modal
      data-testid="RCE_RestoreAutoSaveModal"
      data-mce-component={true}
      label={formatMessage('Restore auto-save?')}
      open={props.open}
      shouldCloseOnDocumentClick={false}
      shouldReturnFocus={true}
      size="medium"
      onDismiss={props.onNo}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="medium"
          color="primary"
          onClick={props.onNo}
          screenReaderLabel={formatMessage('Close')}
        />
        <Heading>{formatMessage('Found auto-saved content')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <View as="div" margin="small">
          <Alert variant="info" margin="none">
            {formatMessage(
              'Auto-saved content exists. Would you like to load the auto-saved content instead?'
            )}
          </Alert>
        </View>
        <ToggleGroup
          summary={formatMessage('Preview')}
          toggleLabel={toggleLabel}
          onToggle={(_e, expanded) => {
            setPreviewExpanded(expanded)
          }}
        >
          <View
            as="div"
            dangerouslySetInnerHTML={{__html: props.savedContent}}
            padding="0 x-small"
            overflowX="auto"
          />
        </ToggleGroup>
      </Modal.Body>
      <Modal.Footer>
        <Button margin="0 x-small" onClick={props.onNo}>
          {formatMessage('No')}
        </Button>
        &nbsp;
        <Button color="primary" onClick={props.onYes}>
          {formatMessage('Yes')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

RestoreAutoSaveModal.propTypes = {
  savedContent: string,
  open: bool.isRequired,
  onNo: func.isRequired,
  onYes: func.isRequired,
}

RestoreAutoSaveModal.defaultProps = {
  savedContent: '',
}
