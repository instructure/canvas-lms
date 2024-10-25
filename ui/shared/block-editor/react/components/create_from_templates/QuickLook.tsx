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
import type {BlockTemplate} from '../../types'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Modal} from '@instructure/ui-modal'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import BlockEditorView from '../../BlockEditorView'
import {LATEST_BLOCK_DATA_VERSION} from '../../utils/transformations'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('block-editor')

export default function QuickLook({
  template,
  close,
  customize,
}: {
  template?: BlockTemplate
  close: () => void
  customize: () => void
}) {
  if (!template) {
    return null
  }

  return (
    <Modal label={I18n.t('Template: Quick Look')} open={true} size="medium">
      <Modal.Header>
        <CloseButton placement="end" offset="small" onClick={close} screenReaderLabel="Close" />
        <Heading level="h3">{I18n.t('Template: Quick Look')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <View as="div" margin="small" padding="small" borderWidth="small" borderRadius="large">
          {template.node_tree && (
            <BlockEditorView
              content={{
                version: LATEST_BLOCK_DATA_VERSION,
                blocks: JSON.stringify(template.node_tree.nodes),
              }}
            />
          )}
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Button color="secondary" margin="none small" onClick={close}>
          {I18n.t('Close')}
        </Button>
        <Button color="primary" onClick={customize}>
          {I18n.t('Customize')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
