/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useRef} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import EditorJS from '@editorjs/editorjs'
import Header from '@editorjs/header'
import NestedList from '@editorjs/nested-list'
import Paragraph from '@editorjs/paragraph'
import Quote from '@editorjs/quote'

import {View} from '@instructure/ui-view'

const I18n = useI18nScope('block-editor')

export default function BlockEditor() {
  const editor = useRef<EditorJS | null>(null)

  React.useEffect(() => {
    editor.current = new EditorJS({
      holder: 'canvas-block-editor',
      tools: {
        header: {
          class: Header,
          inlineToolbar: true,
        },
        list: {
          class: NestedList,
          inlineToolbar: true,
          config: {
            defaultStyle: 'unordered',
          },
        },
        paragraph: {
          class: Paragraph,
          inlineToolbar: false,
        },
        quote: {
          class: Quote,
          config: {
            quotePlaceholder: 'Enter your quote here',
          },
        },
      },
      defaultBlock: 'paragraph',
      placeholder: I18n.t('Press tab for more options'),
    })
    window.block_editor = editor.current
  }, [])

  return (
    <View
      as="span"
      display="inline-block"
      width="100%"
      maxWidth="100%"
      margin="small"
      padding="small"
      background="primary"
      shadow="above"
      borderRadius="large large none none"
    >
      <style>
        {`
        .ce-block__content {
          max-width: 95%;
        }
        .ce-toolbar__content {
          max-width: 95%;
        }
      `}
      </style>
      <div id="canvas-block-editor" data-testid="canvas-block-editor" />
    </View>
  )
}
