/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import tinymce from 'tinymce'
import formatMessage from '../../../format-message'
import clickCallback from './clickCallback'

tinymce.PluginManager.add('instructure_wordcount', function (ed) {
  ed.addCommand('instructureWordcount', () => clickCallback(ed, document, {skipEditorFocus: false}))

  ed.ui.registry.addMenuItem('instructure_wordcount', {
    text: formatMessage('Word Count'),
    icon: 'character-count',
    onAction: () => ed.execCommand('instructureWordcount'),
  })
})
