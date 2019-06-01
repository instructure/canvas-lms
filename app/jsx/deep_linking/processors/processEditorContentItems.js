/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {send} from 'jsx/shared/rce/RceCommandShim'
import $ from 'jquery'
import ContentItemProcessor from '../ContentItemProcessor'
import I18n from 'i18n!external_content.success'

export default function processEditorContentItems(event, editor, dialog) {

  const processor = ContentItemProcessor.fromEvent(event, processHandler)

  if (!processor) { return }

  processor
    .process(editor)
    .finally(() => {
      // Remove "unsaved changes" warnings and close modal
      dialog.close()
    })
    .catch((e) => {
      console.error(e)
      $.flashError(I18n.t('Error retrieving content'))
    })
}

export async function processHandler(editor) {
  this.contentItems.forEach(contentItem => {
    if (Object.keys(this.typeMap).includes(contentItem.type)) {
      const selection = editor.selection && editor.selection.getContent()
      const contentItemModel = new this.typeMap[contentItem.type](
        contentItem,
        this.ltiEndpoint,
        selection
      )
      send($(`#${editor.id}`), 'insert_code', contentItemModel.toHtmlString())
    }
  })
}