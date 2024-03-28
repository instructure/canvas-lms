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

import * as browser from '../common/browser'
import tinymce from 'tinymce'

// load theme
import 'tinymce/themes/silver/theme'
// since tinymce 5.3, default icons are loaded dynamically, but
// w/o importing, webpack doesn't have them
import 'tinymce/icons/default'

// add tinymce plugins
import 'tinymce/plugins/autolink/plugin'
import 'tinymce/plugins/autoresize/plugin'
import 'tinymce/plugins/link/plugin'
import 'tinymce/plugins/noneditable/plugin'
import 'tinymce/plugins/media/plugin'
import 'tinymce/plugins/directionality/plugin'
import 'tinymce/plugins/lists/plugin'
import 'tinymce/plugins/textpattern/plugin'
import 'tinymce/plugins/wordcount/plugin'
import 'tinymce/plugins/paste/plugin'
import 'tinymce/plugins/table/plugin'
import 'tinymce/plugins/hr/plugin'
import 'tinymce/plugins/searchreplace/plugin'

// add custom plugins
import './plugins/instructure-ui-icons/plugin'
import './plugins/instructure_condensed_buttons/plugin'
import './plugins/instructure_equation/plugin'
import './plugins/instructure_image/plugin'
import './plugins/instructure_rce_external_tools/plugin'
import './plugins/instructure_record/plugin'
import './plugins/instructure_links/plugin'
import './plugins/instructure_documents/plugin'
import './plugins/instructure_html_view/plugin'
import './plugins/instructure_media_embed/plugin'
import './plugins/instructure_icon_maker/plugin'
import './plugins/instructure_wordcount/plugin'
import './plugins/instructure_paste/plugin'
import './plugins/instructure_fullscreen/plugin'
import './plugins/instructure_studio_media_options/plugin'
import './plugins/instructure_search_and_replace/plugin'
import './plugins/tinymce-a11y-checker/plugin'

// prevent tinymce from loading language scripts with explicit
// language_url of 'none'
const originalScriptAdd = tinymce.ScriptLoader.add
tinymce.ScriptLoader.add = function (url) {
  if (url !== 'none') {
    originalScriptAdd.apply(tinymce.ScriptLoader, arguments)
  }
}

browser.setFromTinymce(tinymce)

export default tinymce
