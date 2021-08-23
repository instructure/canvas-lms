/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import EditorConfig from './tinymce.config'
import INST from 'browser-sniffer'
import mergeConfig from './util/mergeConfig'

function editorOptions(width, id, tinyMCEInitOptions, enableBookmarkingOverride, tinymce) {
  const editorConfig = new EditorConfig(tinymce, INST, width, id)

  const config = {
    ...editorConfig.defaultConfig(),
    setup: ed => {
      if (!ENV.use_rce_enhancements) {
        ed.on('init', () => {
          const getDefault = mod => (mod.default ? mod.default : mod)
          const EditorAccessibility = getDefault(require('./jquery/editorAccessibility'))
          new EditorAccessibility(ed).accessiblize()
        })
      }
    }
  }

  return {
    ...config,
    ...mergeConfig(tinyMCEInitOptions.optionsToMerge || [], config, tinyMCEInitOptions.tinyOptions)
  }
}

export default editorOptions
