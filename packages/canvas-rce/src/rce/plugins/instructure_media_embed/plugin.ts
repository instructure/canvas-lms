/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import clickCallback from './clickCallback'
import formatMessage from '../../../format-message'
import tinymce from 'tinymce'

// Register plugin
tinymce.PluginManager.add('instructure_media_embed', function (ed) {
  ed.addCommand('instructureMediaEmbed', () => clickCallback(ed, document))

  // Register menu item
  ed.ui.registry.addMenuItem('instructure_media_embed', {
    text: formatMessage('Embed'),
    icon: 'embed',
    onAction: () => ed.execCommand('instructureMediaEmbed'),
  })

  // Register toolbar button
  ed.ui.registry.addButton('instructure_media_embed', {
    tooltip: formatMessage('Embed'),
    icon: 'embed',
    onAction: () => ed.execCommand('instructureMediaEmbed'),
  })
})
