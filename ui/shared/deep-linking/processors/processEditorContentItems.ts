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

import {useScope as useI18nScope} from '@canvas/i18n'
import {send} from '@canvas/rce/RceCommandShim'
import $ from 'jquery'
import {contentItemProcessorPrechecks} from '../ContentItemProcessor'
import type {DeepLinkResponse} from '../DeepLinkResponse'
import {contentItemToHtmlString} from '../models/ContentItem'

const I18n = useI18nScope('external_content.success')

type Editor = {
  id: string
  selection?: {getContent: () => string}
}

type Dialog = {
  close: () => void
}

export const isDeepLinkingEvent = (
  event: MessageEvent<unknown>
): event is MessageEvent<DeepLinkResponse> => {
  const data = event.data
  return (
    typeof data === 'object' &&
    data !== null &&
    'content_items' in data &&
    Array.isArray(data.content_items)
  )
}

export default function processEditorContentItems(
  event: {data: DeepLinkResponse},
  editor: Editor,
  dialog: Dialog
) {
  contentItemProcessorPrechecks(event.data)

  const editorSelection = editor.selection && editor.selection.getContent()

  try {
    event.data.content_items
      .map(
        contentItemToHtmlString({
          ltiEndpoint: event.data.ltiEndpoint,
          editorSelection,
        })
      )
      .forEach(htmlString => {
        send($(`#${editor.id}`), 'insert_code', htmlString)
      })
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(e)
    $.flashError(I18n.t('Error retrieving content'))
  }

  window.requestAnimationFrame(() => {
    dialog.close()
  })
}
