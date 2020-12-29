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

tinymce.create('tinymce.plugins.InstructureHtmlView', {
  init(ed) {
    // Register commands
    ed.addCommand('instructureHtmlView', clickCallback.bind(this, ed, document))

    // Register menu items
    ed.ui.registry.addMenuItem('instructure_html_view', {
      text: formatMessage('HTML Editor'),
      icon: 'htmlview',
      onAction: () => ed.execCommand('instructureHtmlView'),
      onSetup(api) {
        // safari won't fullscreen the textarea that's the raw html editor
        const disable =
          !('requestFullscreen' in document.body) &&
          !ed.rceWrapper.props.use_rce_pretty_html_editor &&
          ed.rceWrapper.state.fullscreenState.isTinyFullscreen
        api.setDisabled(disable)
      }
    })
  }
})

// Register plugin
tinymce.PluginManager.add('instructure_html_view', tinymce.plugins.InstructureHtmlView)
