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
  "description_436c48d7": { "message": "Описание" },
  "down_5831a426": { "message": "Вниз" },
  "icon_215a1dc6": { "message": "Значок" },
  "increase_indent_6af90f7c": { "message": "Увеличить отступ" },
  "insert_math_equation_57c6e767": {
    "message": "Вставить математическое уравнение"
  },
  "links_to_an_external_site_de74145d": {
    "message": "Ссылки на внешний сайт."
  },
  "minimize_file_preview_da911944": { "message": "Уменьшить просмотр файла" },
  "minimize_video_20aa554b": { "message": "Уменьшить видео" },
  "module_90d9fd32": { "message": "Модуль" },
  "navigation_ee9af92d": { "message": "Навигация" },
  "new_quiz_34aacba6": { "message": "Новая контрольная работа" },
  "next_40e12421": { "message": "Далее" },
  "replace_e61834a7": { "message": "Заменить" },
  "reset_95a81614": { "message": "Сброс" },
  "start_over_f7552aa9": { "message": "Начать заново" },
  "the_document_preview_is_currently_being_processed__7d9ea135": {
    "message": "Предварительный просмотр документа в данный момент обрабатывается. Повторите попытку позже."
  },
  "this_document_cannot_be_displayed_within_canvas_7aba77be": {
    "message": "Этот документ нельзя отобразить внутри Canvas."
  },
  "up_c553575d": { "message": "Вверх" }
}


formatMessage.addLocale({ru: locale})
