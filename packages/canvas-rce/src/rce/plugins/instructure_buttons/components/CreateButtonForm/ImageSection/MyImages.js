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

import React, {useState} from 'react'

import {View} from '@instructure/ui-view'
import {Button} from '@instructure/ui-buttons'
import {IconAddLine} from '@instructure/ui-icons'

import formatMessage from '../../../../../../format-message'
import {UploadFile} from '../../../../shared/Upload/UploadFile'

export const MyImages = props => {
  const [isModalOpen, setIsModalOpen] = useState(false)

  function handleFileUpload(
    editor,
    accept,
    selectedPanel,
    uploadData,
    storeProps,
    source,
    onDismiss
  ) {
    // TODO: add the upload logic
    onDismiss()
  }

  return (
    <View as="div" id="buttons-tray-images-section" padding="small">
      <Button onClick={() => setIsModalOpen(true)} renderIcon={IconAddLine}>
        {formatMessage('Add Image')}
      </Button>

      {isModalOpen && (
        <UploadFile
          accept="image/*"
          editor={props.editor}
          label={formatMessage('Add Image')}
          onSubmit={handleFileUpload}
          onDismiss={() => setIsModalOpen(false)}
          panels={['COMPUTER', 'UNSPLASH', 'URL']}
          requireA11yAttributes={false}
        />
      )}
    </View>
  )
}
