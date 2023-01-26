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

import formatMessage from '../../format-message'
import '../tinymce/sv_SE'

const locale = {
  "count_plural_one_item_loaded_other_items_loaded_857023b7": {
    "message": "{ count, plural,\n    one {}\n  other {}\n}"
  },
  "icon_215a1dc6": { "message": "Ikon" },
  "links_to_an_external_site_de74145d": {
    "message": "Länkar till en externa sida."
  },
  "minimize_file_preview_da911944": {
    "message": "Minimera förhandsvisning av fil"
  },
  "minimize_video_20aa554b": { "message": "Minimera video" },
  "replace_e61834a7": { "message": "Ersätt" },
  "reset_95a81614": { "message": "Återställ" },
  "the_document_preview_is_currently_being_processed__7d9ea135": {
    "message": "Förhandsvisningen av dokumentet bearbetas. Vänligen försök igen senare."
  },
  "this_document_cannot_be_displayed_within_canvas_7aba77be": {
    "message": "Det här dokumentet kan inte visas i Canvas."
  }
}


formatMessage.addLocale({sv: locale})
