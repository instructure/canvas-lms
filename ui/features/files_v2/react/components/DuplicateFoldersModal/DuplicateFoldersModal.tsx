/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Alert} from '@instructure/ui-alerts'
import {useScope as createI18nScope} from '@canvas/i18n'
import {datetimeString} from '@canvas/datetime/date-functions'
import {type Folder} from '../../../interfaces/File'

const I18n = createI18nScope('files_v2')

export interface DuplicateFoldersModalProps {
  open: boolean
  duplicateFolders: Folder[]
  onClose: () => void
}

export function DuplicateFoldersModal({
  open,
  duplicateFolders,
  onClose,
}: DuplicateFoldersModalProps) {
  return (
    <Modal
      open={open}
      onDismiss={onClose}
      size="medium"
      label={I18n.t('Duplicate folders are detected')}
      shouldCloseOnDocumentClick={true}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close modal')}
        />
        <Heading>{I18n.t('Duplicate folders are detected')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <View as="div" margin="0 0 medium 0">
          <Alert variant="warning" margin="0 0 medium 0">
            <Text>
              {I18n.t(
                'Multiple folders with the same name exist in this location. Please rename these folders so they have unique names to avoid navigation issues.',
              )}
            </Text>
          </Alert>
        </View>

        <View as="div">
          <Heading level="h3" margin="0 0 small 0">
            {I18n.t('Duplicate folders')}
          </Heading>

          {duplicateFolders.map((folder, index) => (
            <View
              key={folder.id}
              as="div"
              borderWidth="small"
              borderRadius="medium"
              padding="small"
              margin="0 0 small 0"
            >
              <View as="div" margin="0 0 x-small 0">
                <Text weight="bold">{folder.name}</Text>
              </View>
              <View as="div" margin="0 0 x-small 0">
                <Text>
                  <Text weight="bold">{I18n.t('Path:')}</Text> {folder.full_name}
                </Text>
              </View>
              <View as="div">
                <Text>
                  <Text weight="bold">{I18n.t('Created:')}</Text>{' '}
                  {datetimeString(folder.created_at)}
                </Text>
              </View>
            </View>
          ))}
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Button
          onClick={onClose}
          color="primary"
          data-testid="duplicate-folders-modal-close-button"
        >
          {I18n.t('Close')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
