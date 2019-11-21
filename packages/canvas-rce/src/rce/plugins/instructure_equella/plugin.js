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

import htmlEscape from 'escape-html'
import formatMessage from '../../../format-message'
import clickCallback from './clickCallback'

tinymce.create('tinymce.plugins.InstructureEquella', {
  init(ed) {
    ed.addCommand('instructureEquella', clickCallback.bind(this, ed, document))

    ed.ui.registry.addButton('instructure_equella', {
      tooltip: htmlEscape(
        formatMessage({
          default: 'Insert Equella Links',
          description: 'Title for RCE button to insert links to Equella content'
        })
      ),
      onAction: _ => ed.execCommand('instructureEquella'),
      icon: 'equella icon-equella'
    })
  }
})

// Register plugin
tinymce.PluginManager.add('instructure_equella', tinymce.plugins.InstructureEquella)
