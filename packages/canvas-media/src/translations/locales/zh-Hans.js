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
  "afrikaans_da0fe6ee": { "message": "南非语" },
  "albanian_21ed929e": { "message": "阿尔巴尼亚语" },
  "arabic_c5c87acd": { "message": "阿拉伯语" },
  "armenian_12da6118": { "message": "亚美尼亚语" },
  "belarusian_b2f19c76": { "message": "白俄罗斯语" },
  "bulgarian_feccab7e": { "message": "保加利亚语" },
  "captions_inherited_from_a_parent_course_cannot_be__9248fa3a": {
    "message": "无法删除从父课程继承的字幕。"
  },
  "catalan_16f6b78f": { "message": "加泰罗尼亚语" },
  "chinese_111d37f6": { "message": "中文" },
  "chinese_simplified_7f0bd370": { "message": "简体中文" },
  "chinese_traditional_8a7f759d": { "message": "繁体中文" },
  "croatian_d713d655": { "message": "克罗地亚语" },
  "czech_9aa2cbe4": { "message": "捷克语" },
  "danish_c18cdac8": { "message": "丹麦语" },
  "dutch_6d05cee5": { "message": "荷兰语" },
  "english_australia_dc405d82": { "message": "英语 (澳大利亚)" },
  "english_c60612e2": { "message": "英语" },
  "english_canada_12688ee4": { "message": "英语（加拿大）" },
  "english_united_kingdom_a613f831": { "message": "英语 (英国)" },
  "estonian_5e8e2fa4": { "message": "爱沙尼亚语" },
  "file_name_8fd421ff": { "message": "文件名称" },
  "filipino_33339264": { "message": "菲律宾语" },
  "finnish_4df2923d": { "message": "芬兰语" },
  "french_33881544": { "message": "法语" },
  "french_canada_c3d92fa6": { "message": "法语(加拿大)" },
  "galician_7e4508b5": { "message": "加利西亚语" },
  "german_3ec99bbb": { "message": "德语" },
  "greek_65c5b3f7": { "message": "希腊语" },
  "haitian_creole_7eb4195b": { "message": "海地克里奥尔语" },
  "hebrew_88fbf778": { "message": "希伯来语" },
  "hindi_9bcd4b34": { "message": "印地语" },
  "hungarian_fc7d30c9": { "message": "匈牙利语" },
  "icelandic_9d6d35de": { "message": "冰岛语" },
  "indonesian_5f6accd6": { "message": "印度尼西亚语" },
  "irish_567e109f": { "message": "爱尔兰语" },
  "italian_bd3c792d": { "message": "意大利语" },
  "japanese_b5721ca7": { "message": "日语" },
  "korean_da812d9": { "message": "朝鲜语" },
  "latvian_2bbb6aab": { "message": "拉脱维亚语" },
  "lithuanian_5adcbe24": { "message": "立陶宛语" },
  "loading_25990131": { "message": "加载中……" },
  "macedonian_6ed541af": { "message": "马其顿语" },
  "malay_f5dddce4": { "message": "马来语" },
  "maltese_916925e8": { "message": "马耳他语" },
  "maori_new_zealand_5380a95f": { "message": "毛利语（新西兰）" },
  "no_preview_is_available_for_this_file_f940114a": {
    "message": "没有预览可用于此文件。"
  },
  "norwegian_53f391ec": { "message": "挪威语" },
  "norwegian_bokmal_ad5843fa": { "message": "巴克摩挪威语" },
  "norwegian_nynorsk_c785f8a6": { "message": "挪威尼诺斯克语" },
  "persian_a8cadb95": { "message": "波斯语" },
  "polish_4cf2ecaf": { "message": "波兰语" },
  "portuguese_9c212cf4": { "message": "葡萄牙语" },
  "romanian_13670c1e": { "message": "罗马尼亚语" },
  "russian_1e3e197": { "message": "俄语" },
  "serbian_7187f1f2": { "message": "塞尔维亚语" },
  "slovak_69f48e1b": { "message": "斯洛伐克语" },
  "slovenian_30ae5208": { "message": "斯洛文尼亚语" },
  "spanish_de9de5d6": { "message": "西班牙语" },
  "swahili_5caeb4ba": { "message": "斯瓦希里语" },
  "swedish_59a593ca": { "message": "瑞典语" },
  "tagalog_74906db7": { "message": "塔加拉族语" },
  "thai_8f9bc548": { "message": "泰语" },
  "the_selected_file_exceeds_the_maxsize_byte_limit_f7e8c771": {
    "message": "所选文件超过 { maxSize } 字节限制"
  },
  "turkish_5b69578b": { "message": "土耳其语" },
  "ukrainian_945b00b7": { "message": "乌克兰语" },
  "vietnamese_e7a76583": { "message": "越南语" },
  "welsh_42ab94b1": { "message": "威尔士语" },
  "yiddish_f96986df": { "message": "意第绪语" },
  "you_can_replace_by_uploading_a_new_caption_file_6c88ce00": {
    "message": "您可以通过上传新的字幕文件进行替换。"
  }
}


formatMessage.addLocale({'zh-Hans': locale})
