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
  "afrikaans_da0fe6ee": { "message": "อาฟริกา" },
  "albanian_21ed929e": { "message": "อัลเบเนีย" },
  "arabic_c5c87acd": { "message": "อารบิก" },
  "armenian_12da6118": { "message": "อาร์เมเนีย" },
  "belarusian_b2f19c76": { "message": "เบลารุส" },
  "bulgarian_feccab7e": { "message": "บัลแกเรีย" },
  "captions_inherited_from_a_parent_course_cannot_be__9248fa3a": {
    "message": "คำบรรยายที่รับต่อมาจากบทเรียนต้นทางไม่สามารถลบได้"
  },
  "catalan_16f6b78f": { "message": "คาตาลัน" },
  "chinese_111d37f6": { "message": "จีน" },
  "chinese_simplified_7f0bd370": { "message": "จีนใหม่" },
  "chinese_traditional_8a7f759d": { "message": "จีนเก่า" },
  "croatian_d713d655": { "message": "โครเอเชีย" },
  "czech_9aa2cbe4": { "message": "เชก" },
  "danish_c18cdac8": { "message": "เดนมาร์ก" },
  "dutch_6d05cee5": { "message": "เนเธอร์แลนด์" },
  "english_australia_dc405d82": { "message": "อังกฤษ (ออสเตรเลีย)" },
  "english_c60612e2": { "message": "อังกฤษ" },
  "english_canada_12688ee4": { "message": "อังกฤษ (แคนาดา)" },
  "english_united_kingdom_a613f831": { "message": "อังกฤษ (สหราชอาณาจักร)" },
  "estonian_5e8e2fa4": { "message": "เอสโทเนีย" },
  "file_name_8fd421ff": { "message": "ชื่อไฟล์" },
  "filipino_33339264": { "message": "ฟิลิปปินส์" },
  "finnish_4df2923d": { "message": "ฟินแลนด์" },
  "french_33881544": { "message": "ฝรั่งเศส" },
  "french_canada_c3d92fa6": { "message": "ฝรั่งเศส (แคนาดา)" },
  "galician_7e4508b5": { "message": "กาลิเซีย" },
  "german_3ec99bbb": { "message": "เยอรมัน" },
  "greek_65c5b3f7": { "message": "กรีก" },
  "haitian_creole_7eb4195b": { "message": "ครีโอลเฮติ" },
  "hebrew_88fbf778": { "message": "ฮีบรู" },
  "hindi_9bcd4b34": { "message": "ฮินดู" },
  "hungarian_fc7d30c9": { "message": "ฮังการี" },
  "icelandic_9d6d35de": { "message": "ไอซ์แลนด์" },
  "indonesian_5f6accd6": { "message": "อินโดนีเซีย" },
  "irish_567e109f": { "message": "ไอร์แลนด์" },
  "italian_bd3c792d": { "message": "อิตาลี" },
  "japanese_b5721ca7": { "message": "ญี่ปุ่น" },
  "korean_da812d9": { "message": "เกาหลี" },
  "latvian_2bbb6aab": { "message": "ลัทเวีย" },
  "lithuanian_5adcbe24": { "message": "ลิทัวเนีย" },
  "loading_25990131": { "message": "กำลังโหลด..." },
  "macedonian_6ed541af": { "message": "มาซิโดเนีย" },
  "malay_f5dddce4": { "message": "มาเลย์" },
  "maltese_916925e8": { "message": "มอลต้า" },
  "maori_new_zealand_5380a95f": { "message": "เมารี (นิวซีแลนด์)" },
  "no_preview_is_available_for_this_file_f940114a": {
    "message": "ไม่มีตัวอย่างแสดงสำหรับไฟล์นี้"
  },
  "norwegian_53f391ec": { "message": "นอร์เวย์" },
  "norwegian_bokmal_ad5843fa": { "message": "บุ๊กมอลนอร์เวย์" },
  "norwegian_nynorsk_c785f8a6": { "message": "นือนอสก์นอร์เวย์" },
  "persian_a8cadb95": { "message": "เปอร์เซีย" },
  "polish_4cf2ecaf": { "message": "โปแลนด์" },
  "portuguese_9c212cf4": { "message": "โปรตุเกส" },
  "romanian_13670c1e": { "message": "โรมาเนีย" },
  "russian_1e3e197": { "message": "รัสเซีย" },
  "serbian_7187f1f2": { "message": "เซอร์เบีย" },
  "slovak_69f48e1b": { "message": "สโลวัก" },
  "slovenian_30ae5208": { "message": "สโลเวเนีย" },
  "spanish_de9de5d6": { "message": "สเปน" },
  "swahili_5caeb4ba": { "message": "สวาฮีลี" },
  "swedish_59a593ca": { "message": "สวีเดน" },
  "tagalog_74906db7": { "message": "ตากาล็อก" },
  "thai_8f9bc548": { "message": "ไทย" },
  "the_selected_file_exceeds_the_maxsize_byte_limit_f7e8c771": {
    "message": "ไฟล์ที่เลือกมีขนาดเกิน { maxSize } ไบต์"
  },
  "turkish_5b69578b": { "message": "ตุรกี" },
  "ukrainian_945b00b7": { "message": "ยูเครน" },
  "vietnamese_e7a76583": { "message": "เวียดนาม" },
  "welsh_42ab94b1": { "message": "เวลส์" },
  "yiddish_f96986df": { "message": "ยิดติช" },
  "you_can_replace_by_uploading_a_new_caption_file_6c88ce00": {
    "message": "คุณสามารถแทนที่ได้โดยการอัพโหลดไฟล์คำบรรยายใหม่"
  }
}


formatMessage.addLocale({th: locale})
