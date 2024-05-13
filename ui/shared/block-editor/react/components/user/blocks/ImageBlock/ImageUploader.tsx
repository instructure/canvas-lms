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

import React, {useCallback, useState} from 'react'

import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {UploadFileModal} from '../../../../FileUpload/UploadFileModal'
import type {ImageVariant} from './ImageBlock'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('block-editor-image-upload')

// by looking indevtools what's passed as props
/*
decorations: []
deleteNode: ()=>this.deleteNode()
editor: Editor {callbacks: {…}, isFocused: false, extensionStorage: {…}, options: {…}, isCapturingTransaction: false, …}
extension: Node {type: 'node', name: 'imageuploadview', parent: null, child: null, config: {…}, …}
getPos: ()=>this.getPos()
node: Node {type: NodeType, attrs: {…}, marks: Array(0), content: Fragment}
selected: false
updateAttributes: (attributes = {})=>this.updateAttributes(attributes)
*/
interface ImageUploadeProps {
  node: Node & {
    attrs: {
      src: string
      variant: ImageVariant
    }
  }
}

const ImageUploader = ({editor, getPos, node}: ImageUploadeProps) => {
  const [showUploadModal, setShowUploadModal] = useState(false)

  const handleOpenModal = useCallback(() => {
    setShowUploadModal(true)
    const pos = getPos()
    editor.commands.setNodeSelection(pos)
  }, [editor.commands, getPos])

  const handleDismissModal = useCallback(() => {
    setShowUploadModal(false)
    // const from = getPos()
    // const to = from + node.nodeSize
    // editor.commands.deleteRange({from, to})
  }, [])

  const handleSave = useCallback(
    (fileUrl: string | null) => {
      if (fileUrl) {
        if (node.attrs.variant === 'hero') {
          editor.chain().focus().setHeroImage({src: fileUrl}).run()
        } else {
          // editor.chain().focus().setImage({src: fileUrl}).run()
          editor.chain().focus().setResizableImage({src: fileUrl}).run()
        }
        // some day if we do inline images, this might work
        // editor
        //   .chain()
        //   .focus()
        //   .insertContent({
        //     type: 'resizableimage',
        //     attrs: {src: fileUrl},
        //   })
        //   .run()
      } else {
        editor.chain().focus().clearNodes().run()
      }
      setShowUploadModal(false)
    },
    [editor, node.attrs.variant]
  )

  return (
    <UploadFileModal
      imageUrl={null}
      open={showUploadModal}
      variant={node.attrs.variant}
      onDismiss={handleDismissModal}
      onSave={handleSave}
    />
  )
}

export {ImageUploader}
