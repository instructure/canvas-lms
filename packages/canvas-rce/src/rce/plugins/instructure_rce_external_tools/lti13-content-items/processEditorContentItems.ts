// @ts-nocheck
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

import {Lti13ContentItemJson} from './Lti13ContentItemJson'
import {rceLti13ContentItemFromJson} from './rceLti13ContentItemFromJson'
import {ExternalToolsEnv} from '../ExternalToolsEnv'
import {showFlashAlert} from '../../../../common/FlashAlert'
import formatMessage from '../../../../format-message'

export default function processEditorContentItems(
  event: {
    data?: {
      content_items?: Lti13ContentItemJson[] | null
      ltiEndpoint?: string | null
    }
  },
  env: ExternalToolsEnv,
  dialog: {
    close()
  } | null
) {
  try {
    const ltiEndpoint = event.data?.ltiEndpoint
    const selection = env.editorSelection

    const eventContentItems = event.data?.content_items ?? []

    let unsupportedItemWarningShown = false

    for (const inputItem of eventContentItems) {
      const parsedItem = rceLti13ContentItemFromJson(inputItem, {
        ltiEndpoint: ltiEndpoint ?? null,
        selection: selection ?? null,
        containingCanvasLtiToolId: env.containingCanvasLtiToolId,
        ltiIframeAllowPolicy: env.ltiIframeAllowPolicy,
      })

      if (parsedItem != null) {
        env.insertCode(parsedItem.toHtmlString())
      } else if (!unsupportedItemWarningShown) {
        showFlashAlert({
          message: formatMessage(
            'Could not insert content: "{itemType}" items are not currently supported in Canvas.',
            {itemType: inputItem.type ?? 'unknown'}
          ),
          type: 'warning',
          err: null,
        })

        unsupportedItemWarningShown = true
      }
    }

    // Remove "unsaved changes" warnings and close modal
    if (event.data?.content_items) {
      dialog?.close()
    }
  } catch (e) {
    showFlashAlert({
      message: formatMessage('Failed to retrieve content from external tool'),
      type: 'error',
      err: e,
    })
  }
}
