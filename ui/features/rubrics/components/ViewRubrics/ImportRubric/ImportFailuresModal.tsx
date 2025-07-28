/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import _ from 'lodash'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {List} from '@instructure/ui-list'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
// @ts-expect-error
import type {RubricImport} from '../../../types/Rubric'

const I18n = createI18nScope('rubrics-import-failure-modal')

type ImportFailuresModalProps = {
  isOpen: boolean
  onDismiss: () => void
  rubricImports: RubricImport[]
}
export const ImportFailuresModal = ({
  isOpen,
  onDismiss,
  rubricImports,
}: ImportFailuresModalProps) => {
  const {fileNames, messages} = rubricImports.reduce(
    (prev, curr) => {
      prev.fileNames.push(curr.attachment.filename)
      // @ts-expect-error
      prev.messages.push(...curr.errorData.map(x => x.message))

      return prev
    },
    {fileNames: [] as string[], messages: [] as string[]},
  )

  return (
    <Modal
      open={isOpen}
      onDismiss={onDismiss}
      size="small"
      label={I18n.t('Import Failures')}
      shouldCloseOnDocumentClick={true}
    >
      <Modal.Header>
        <CloseButton placement="end" offset="small" onClick={onDismiss} screenReaderLabel="Close" />
        <Heading>{I18n.t('Import Failed')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <View as="div" data-testid="import-rubric-failure-header">
          {I18n.t('The import failed for the following file(s):')}
        </View>
        {/* @ts-expect-error */}
        {fileNames.map((fileName, i) => (
          <View as="div" margin="x-small 0 0" key={`${fileName}-${i}`}>
            <Text weight="bold">{fileName}</Text>
          </View>
        ))}
        <View as="div" margin="large 0 0">
          {I18n.t('This import failure was due to the following:')}
        </View>
        <View as="div" margin="x-small 0 0 0">
          <List margin="0 0 medium">
            {_.uniq(messages).map(message => (
              <List.Item data-testid="import-failure-message" key={`${message}`}>
                {/* @ts-expect-error */}
                {message}
              </List.Item>
            ))}
          </List>
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={onDismiss} margin="0 x-small 0 0">
          {I18n.t('Close')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
