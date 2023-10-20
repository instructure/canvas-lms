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
  "afrikaans_da0fe6ee": { "message": "南非荷蘭語" },
  "albanian_21ed929e": { "message": "阿爾巴尼亞語" },
  "arabic_c5c87acd": { "message": "阿拉伯語" },
  "armenian_12da6118": { "message": "亞美尼亞語" },
  "belarusian_b2f19c76": { "message": "白俄羅斯語" },
  "bulgarian_feccab7e": { "message": "保加利亞語" },
  "captions_inherited_from_a_parent_course_cannot_be__9248fa3a": {
    "message": "自父項課程繼承的字幕已移除。"
  },
  "catalan_16f6b78f": { "message": "加泰隆尼亞語" },
  "chinese_111d37f6": { "message": "中文" },
  "chinese_simplified_7f0bd370": { "message": "簡體中文" },
  "chinese_traditional_8a7f759d": { "message": "繁體中文" },
  "croatian_d713d655": { "message": "克羅埃西亞語" },
  "czech_9aa2cbe4": { "message": "捷克語" },
  "danish_c18cdac8": { "message": "丹麥語" },
  "dutch_6d05cee5": { "message": "荷蘭語" },
  "english_australia_dc405d82": { "message": "英語（澳大利亞）" },
  "english_c60612e2": { "message": "英語" },
  "english_canada_12688ee4": { "message": "英語（加拿大）" },
  "english_united_kingdom_a613f831": { "message": "英語（英國）" },
  "estonian_5e8e2fa4": { "message": "愛沙尼亞語" },
  "file_name_8fd421ff": { "message": "檔案名稱" },
  "filipino_33339264": { "message": "菲律賓語" },
  "finnish_4df2923d": { "message": "芬蘭語" },
  "french_33881544": { "message": "法語" },
  "french_canada_c3d92fa6": { "message": "法語（加拿大）" },
  "galician_7e4508b5": { "message": "加利西亞語" },
  "german_3ec99bbb": { "message": "德語" },
  "greek_65c5b3f7": { "message": "希臘語" },
  "haitian_creole_7eb4195b": { "message": "海地語" },
  "hebrew_88fbf778": { "message": "希伯來語" },
  "hindi_9bcd4b34": { "message": "印地語" },
  "hungarian_fc7d30c9": { "message": "匈牙利語" },
  "icelandic_9d6d35de": { "message": "冰島語" },
  "indonesian_5f6accd6": { "message": "印尼語" },
  "irish_567e109f": { "message": "愛爾蘭語" },
  "italian_bd3c792d": { "message": "義大利語" },
  "japanese_b5721ca7": { "message": "日語" },
  "korean_da812d9": { "message": "韓語" },
  "latvian_2bbb6aab": { "message": "拉脫維亞語" },
  "lithuanian_5adcbe24": { "message": "立陶宛語" },
  "loading_25990131": { "message": "正在載入……" },
  "macedonian_6ed541af": { "message": "馬其頓語" },
  "malay_f5dddce4": { "message": "馬來語" },
  "maltese_916925e8": { "message": "馬爾他語" },
  "maori_new_zealand_5380a95f": { "message": "毛利語（紐西蘭）" },
  "no_preview_is_available_for_this_file_f940114a": {
    "message": "本檔案不支援預覽。"
  },
  "norwegian_53f391ec": { "message": "挪威語" },
  "norwegian_bokmal_ad5843fa": { "message": "書面挪威語" },
  "norwegian_nynorsk_c785f8a6": { "message": "新挪威語" },
  "persian_a8cadb95": { "message": "波斯語" },
  "polish_4cf2ecaf": { "message": "波蘭語" },
  "portuguese_9c212cf4": { "message": "葡萄牙語" },
  "romanian_13670c1e": { "message": "羅馬尼亞語" },
  "russian_1e3e197": { "message": "俄語" },
  "serbian_7187f1f2": { "message": "塞爾維亞語" },
  "slovak_69f48e1b": { "message": "斯洛伐克語" },
  "slovenian_30ae5208": { "message": "斯洛維尼亞文" },
  "spanish_de9de5d6": { "message": "西班牙語" },
  "swahili_5caeb4ba": { "message": "斯瓦希里語" },
  "swedish_59a593ca": { "message": "瑞典語" },
  "tagalog_74906db7": { "message": "他加祿語" },
  "thai_8f9bc548": { "message": "泰語" },
  "the_selected_file_exceeds_the_maxsize_byte_limit_f7e8c771": {
    "message": "選取的檔案超過 { maxSize } 位元組限制"
  },
  "turkish_5b69578b": { "message": "土耳其語" },
  "ukrainian_945b00b7": { "message": "烏克蘭語" },
  "vietnamese_e7a76583": { "message": "緬甸語" },
  "welsh_42ab94b1": { "message": "威爾斯語" },
  "yiddish_f96986df": { "message": "意第緒語" },
  "you_can_replace_by_uploading_a_new_caption_file_6c88ce00": {
    "message": "您可以透過上傳新的字幕檔來取代。"
  }
}


formatMessage.addLocale({'zh-HK': locale})
