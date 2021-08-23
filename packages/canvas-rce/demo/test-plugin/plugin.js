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

import formatMessage from '../../src/format-message'
import clickCallback from './clickCallback'
import {IconAdminToolsLine} from '@instructure/ui-icons/es/svg'

tinymce.create('tinymce.plugins.RceDemoTest', {
  init(ed) {
    ed.addCommand('RceDemoTest', clickCallback.bind(this, ed, document))
    ed.ui.registry.addIcon('rce-demo-test', IconAdminToolsLine.src)

    ed.ui.registry.addButton('rce_demo_test', {
      tooltip: formatMessage('Demo test plugin'),
      onAction: _ => ed.execCommand('RceDemoTest'),
      icon: 'rce-demo-test'
    })

    ed.ui.registry.addMenuItem('rce_demo_test', {
      text: formatMessage('Demo test plugin'),
      icon: 'rce-demo-test',
      onAction: () => ed.execCommand('RceDemoTest')
    })
  }
})

// Register plugin
tinymce.PluginManager.add('rce_demo_test', tinymce.plugins.RceDemoTest)
