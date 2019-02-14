/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import tinymce from 'compiled/editor/stocktiny'
import initializeExternalTools from './initializeExternalTools'
import ExternalToolsHelper from './ExternalToolsHelper'
import INST from '../../INST'

tinymce.create('tinymce.plugins.InstructureExternalTools', {
  init(ed, url) {
    return initializeExternalTools.init(ed, url, INST)
  },
  getInfo() {
    return {
      longname: 'InstructureExternalTools',
      author: 'Brian Whitmer',
      authorurl: 'http://www.instructure.com',
      infourl: 'http://www.instructure.com',
      version: `${tinymce.majorVersion}.${tinymce.minorVersion}`
    }
  }
})

// Register plugin
tinymce.PluginManager.add('instructure_external_tools', tinymce.plugins.InstructureExternalTools)

export default tinymce
