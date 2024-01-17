/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import formatMessage from '../../../format-message'
import clickCallback from './clickCallback'
import tinymce from 'tinymce'

// Register plugin
tinymce.PluginManager.add('instructure_html_view', function (ed) {
  // Register commands
  ed.addCommand('instructureHtmlView', () => clickCallback())

  // Register menu items
  ed.ui.registry.addMenuItem('instructure_html_view', {
    text: formatMessage('HTML Editor'),
    icon: 'htmlview',
    onAction: () => ed.execCommand('instructureHtmlView'),
    onSetup(api) {
      api.setDisabled(false)

      return () => undefined
    },
  })
})
