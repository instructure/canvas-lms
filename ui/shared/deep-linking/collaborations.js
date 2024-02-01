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

import $ from 'jquery'
import {addDeepLinkingListener as addOriginalListener} from './DeepLinking'
import processSingleContentItem from './processors/processSingleContentItem'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('collaborations')

export const addDeepLinkingListener = () => {
  window.removeEventListener('message', handleDeepLinking)
  addOriginalListener(handleDeepLinking)
}

/*
 * Creates or updates a Collaboration in Canvas.
 *
 * A processing function called by both the
 * LTI Advantage handleDeepLinking handler and the
 * LTI 1.1 content item handler.
 */
export function onExternalContentReady({contentItems, service_id, tool_id}) {
  const contentItem = {contentItems: JSON.stringify(contentItems)}
  if (service_id) {
    updateCollaboration(contentItem, service_id, tool_id)
  } else {
    createCollaboration(contentItem, tool_id)
  }
}

/*
 * Handles deep linking response events in
 * the collaborations UI. Only a single LtiResourceLink
 * content item is supported
 */
export const handleDeepLinking = async event => {
  try {
    const item = processSingleContentItem(event)
    if (typeof item !== 'object') {
      $.flashError(I18n.t('Error retrieving content from tool (bad content item)'))
    } else {
      onExternalContentReady({
        service_id: event.data?.service_id,
        tool_id: event.data?.tool_id,
        contentItems: [item],
      })
    }
  } catch (e) {
    $.flashError(I18n.t('Error retrieving content from tool'))
  }
}

export function collaborationUrl(id) {
  return window.location.toString() + '/' + id
}

function updateCollaboration(contentItem, collab_id, tool_id) {
  const url =
    document.querySelector('.collaboration_' + collab_id + ' a.title')?.href +
    '?tool_id=' +
    (tool_id || '')
  $.ajaxJSON(url, 'PUT', contentItem, collaborationSuccess, _msg => {
    $.screenReaderFlashMessage(I18n.t('Collaboration update failed'))
  })
}

function createCollaboration(contentItem, tool_id) {
  const url =
    document.querySelector('#new_collaboration')?.getAttribute('action') +
    '?tool_id=' +
    (tool_id || '')
  $.ajaxJSON(url, 'POST', contentItem, collaborationSuccess, _msg => {
    $.screenReaderFlashMessage(I18n.t('Collaboration creation failed'))
  })
}

function collaborationSuccess(msg) {
  openCollaboration(msg.collaboration.id)
  window.location.reload()
}

function openCollaboration(id) {
  window.open(collaborationUrl(id))
}
