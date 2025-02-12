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
import KeyboardShortcutModal from './KeyboardShortcutModal'
import {useScope as useI18nScope} from '@canvas/i18n'

const DiscussionTopicKeyboardShortcutModal = (props) => {
  const I18n = useI18nScope('discussionTopicKeyboradShortcutModal')
  const SHORTCUTS = [
    {keycode: 'e', description: I18n.t('Edit Current Message')},
    {keycode: 'd', description: I18n.t('Delete Current Message')},
    {keycode: 'r', description: I18n.t('Reply to Current Message')},
    {keycode: 'n', description: I18n.t('Reply to Topic')},
    {keycode: 'x', description: I18n.t('Expand/Collapse replies')},
    {keycode: 'l', description: I18n.t('Like the Current Message')},
  ]

  return <KeyboardShortcutModal {...props} shortcuts={SHORTCUTS} />
}

export default DiscussionTopicKeyboardShortcutModal