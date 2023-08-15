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

const locale = {
  "afrikaans_da0fe6ee": { "message": "الأفريقانية" },
  "albanian_21ed929e": { "message": "الألبانية" },
  "arabic_c5c87acd": { "message": "العربية" },
  "armenian_12da6118": { "message": "الأرمينية" },
  "belarusian_b2f19c76": { "message": "البيلاروسية" },
  "bulgarian_feccab7e": { "message": "البلغارية" },
  "captions_inherited_from_a_parent_course_cannot_be__9248fa3a": {
    "message": "لا يمكن إزالة التسميات التوضيحية الموروثة من مساق أصلي."
  },
  "catalan_16f6b78f": { "message": "الكاتالونية" },
  "chinese_111d37f6": { "message": "الصينية" },
  "chinese_simplified_7f0bd370": { "message": "الصينية المبسطة" },
  "chinese_traditional_8a7f759d": { "message": "الصينية التقليدية" },
  "croatian_d713d655": { "message": "الكرواتية" },
  "czech_9aa2cbe4": { "message": "التشيكية" },
  "danish_c18cdac8": { "message": "الدنماركية" },
  "dutch_6d05cee5": { "message": "الهولندية" },
  "english_australia_dc405d82": { "message": "الإنجليزية (أستراليا)" },
  "english_c60612e2": { "message": "الإنجليزية" },
  "english_canada_12688ee4": { "message": "الإنجليزية (كندا)" },
  "english_united_kingdom_a613f831": {
    "message": "الإنجليزية (المملكة المتحدة)"
  },
  "estonian_5e8e2fa4": { "message": "الإستونية" },
  "file_name_8fd421ff": { "message": "اسم الملف" },
  "filipino_33339264": { "message": "الفلبينية" },
  "finnish_4df2923d": { "message": "الفنلندية" },
  "french_33881544": { "message": "الفرنسية" },
  "french_canada_c3d92fa6": { "message": "الفرنسية (كندا)" },
  "galician_7e4508b5": { "message": "الغاليسية" },
  "german_3ec99bbb": { "message": "الألمانية" },
  "greek_65c5b3f7": { "message": "اليونانية" },
  "haitian_creole_7eb4195b": { "message": "الكريولية الهايتية" },
  "hebrew_88fbf778": { "message": "العبرية" },
  "hindi_9bcd4b34": { "message": "الهندية" },
  "hungarian_fc7d30c9": { "message": "المجرية" },
  "icelandic_9d6d35de": { "message": "الأيسلندية" },
  "indonesian_5f6accd6": { "message": "الإندونيسية" },
  "irish_567e109f": { "message": "الأيرلندية" },
  "italian_bd3c792d": { "message": "الإيطالية" },
  "japanese_b5721ca7": { "message": "اليابانية" },
  "korean_da812d9": { "message": "الكورية" },
  "latvian_2bbb6aab": { "message": "اللاتفية" },
  "lithuanian_5adcbe24": { "message": "الليتوانية" },
  "loading_25990131": { "message": "جارٍ التحميل..." },
  "macedonian_6ed541af": { "message": "المقدونية" },
  "malay_f5dddce4": { "message": "الماليزية" },
  "maltese_916925e8": { "message": "المالطية" },
  "maori_new_zealand_5380a95f": { "message": "ماوري (نيوزلندا)" },
  "no_preview_is_available_for_this_file_f940114a": {
    "message": "لا توجد معاينة متوفرة لهذا الملف."
  },
  "norwegian_53f391ec": { "message": "النرويجية" },
  "norwegian_bokmal_ad5843fa": { "message": "النرويجية (بوكمال)" },
  "norwegian_nynorsk_c785f8a6": { "message": "النرويجية (نينورسك)" },
  "persian_a8cadb95": { "message": "الفارسية" },
  "polish_4cf2ecaf": { "message": "البولندية" },
  "portuguese_9c212cf4": { "message": "البرتغالية" },
  "romanian_13670c1e": { "message": "الرومانية" },
  "russian_1e3e197": { "message": "الروسية" },
  "serbian_7187f1f2": { "message": "الصربية" },
  "slovak_69f48e1b": { "message": "السلوفاكية" },
  "slovenian_30ae5208": { "message": "السلوفينية" },
  "spanish_de9de5d6": { "message": "الإسبانية" },
  "swahili_5caeb4ba": { "message": "السواحلية" },
  "swedish_59a593ca": { "message": "السويدية" },
  "tagalog_74906db7": { "message": "التغالوغ" },
  "thai_8f9bc548": { "message": "التايوانية" },
  "the_selected_file_exceeds_the_maxsize_byte_limit_f7e8c771": {
    "message": "الملف المحدد يتجاوز حد { maxSize } بايت"
  },
  "turkish_5b69578b": { "message": "التركية" },
  "ukrainian_945b00b7": { "message": "الأوكرانية" },
  "vietnamese_e7a76583": { "message": "الفيتنامية" },
  "welsh_42ab94b1": { "message": "الويلزية" },
  "yiddish_f96986df": { "message": "اليديشية" },
  "you_can_replace_by_uploading_a_new_caption_file_6c88ce00": {
    "message": "يمكنك استبداله بتحميل ملف تسمية توضيحية جديد."
  }
}


formatMessage.addLocale({ar: locale})
