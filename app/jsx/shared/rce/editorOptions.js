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

import _ from 'underscore'
import EditorConfig from 'tinymce.config'
import setupAndFocusTinyMCEConfig from 'setupAndFocusTinyMCEConfig'
import INST from 'INST'

  function editorOptions (width, id, tinyMCEInitOptions, enableBookmarkingOverride, tinymce){
    var editorConfig = new EditorConfig(tinymce, INST, width, id);

    // RichContentEditor takes care of the autofocus functionality at a higher level
    var autoFocus = undefined

    return _.extend({},
      editorConfig.defaultConfig(),
      setupAndFocusTinyMCEConfig(tinymce, autoFocus, enableBookmarkingOverride),
      (tinyMCEInitOptions.tinyOptions || {})
    );

  };

export default editorOptions
