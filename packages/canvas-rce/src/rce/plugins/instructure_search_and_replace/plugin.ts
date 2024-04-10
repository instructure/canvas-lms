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

import tinymce, {Editor} from 'tinymce'
import formatMessage from '../../../format-message'
import clickCallback from './clickCallback'

tinymce.PluginManager.add('instructure_search_and_replace', function (editor) {
  // We use the searchreplace plugins API
  if (!editor.plugins?.searchreplace) return

  const launchFindModal = (ed: Editor) => (): void => {
    clickCallback(ed, document)
  }

  editor.addCommand('launch_instructure_search_and_replace', launchFindModal(editor))

  editor.ui.registry.addMenuItem('instructure_search_and_replace', {
    text: formatMessage('Find and Replace'),
    icon: 'search',
    shortcut: 'Meta+F',
    onAction: () => editor.execCommand('launch_instructure_search_and_replace'),
  })

  editor.shortcuts.add('Meta+F', '', launchFindModal(editor))
})
