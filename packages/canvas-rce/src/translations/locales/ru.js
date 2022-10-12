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
import '../tinymce/ru'

const locale = {
  "count_plural_one_item_loaded_other_items_loaded_857023b7": {
    "message": "{ count, plural,\n    one {}\n    few {}\n   many {}\n  other {}\n}"
  },
  "decrease_indent_d9cf469d": { "message": "Уменьшить отступ" },
  "icon_215a1dc6": { "message": "Значок" },
  "increase_indent_6af90f7c": { "message": "Увеличить отступ" },
  "replace_e61834a7": { "message": "Заменить" },
  "reset_95a81614": { "message": "Сброс" }
}


formatMessage.addLocale({ru: locale})
