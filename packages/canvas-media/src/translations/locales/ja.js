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
  "afrikaans_da0fe6ee": { "message": "アフリカーンス語" },
  "albanian_21ed929e": { "message": "アルバニア語" },
  "arabic_c5c87acd": { "message": "アラビア語" },
  "armenian_12da6118": { "message": "英語（米語）" },
  "belarusian_b2f19c76": { "message": "ベラルーシ語" },
  "bulgarian_feccab7e": { "message": "ブルガリア語" },
  "captions_inherited_from_a_parent_course_cannot_be__9248fa3a": {
    "message": "ペアレントコースから継承されたキャプションは削除できません。"
  },
  "catalan_16f6b78f": { "message": "カタロニア語" },
  "chinese_111d37f6": { "message": "中国語" },
  "chinese_simplified_7f0bd370": { "message": "中国語（簡体字）" },
  "chinese_traditional_8a7f759d": { "message": "中国語（繁体字）" },
  "croatian_d713d655": { "message": "クロアチア語" },
  "czech_9aa2cbe4": { "message": "チェコ語" },
  "danish_c18cdac8": { "message": "デンマーク語" },
  "dutch_6d05cee5": { "message": "オランダ語" },
  "english_australia_dc405d82": { "message": "英語 (オーストラリア)" },
  "english_c60612e2": { "message": "英語" },
  "english_canada_12688ee4": { "message": "英語 (カナダ)" },
  "english_united_kingdom_a613f831": { "message": "英語 (イギリス)" },
  "estonian_5e8e2fa4": { "message": "エストニア語" },
  "file_name_8fd421ff": { "message": "ファイル名" },
  "filipino_33339264": { "message": "フィリピン語" },
  "finnish_4df2923d": { "message": "フィンランド語" },
  "french_33881544": { "message": "フランス語" },
  "french_canada_c3d92fa6": { "message": "フランス語（カナダ）" },
  "galician_7e4508b5": { "message": "ガリシア語" },
  "german_3ec99bbb": { "message": "ドイツ語" },
  "greek_65c5b3f7": { "message": "ギリシャ文字" },
  "haitian_creole_7eb4195b": { "message": "ハイチ・クレオール語" },
  "hebrew_88fbf778": { "message": "ヘブライ語" },
  "hindi_9bcd4b34": { "message": "ヒンディー語" },
  "hungarian_fc7d30c9": { "message": "ハンガリー語" },
  "icelandic_9d6d35de": { "message": "アイスランド語" },
  "indonesian_5f6accd6": { "message": "インドネシア語" },
  "irish_567e109f": { "message": "アイルランド語" },
  "italian_bd3c792d": { "message": "イタリア語" },
  "japanese_b5721ca7": { "message": "日本語" },
  "korean_da812d9": { "message": "韓国語" },
  "latvian_2bbb6aab": { "message": "ラトビア語" },
  "lithuanian_5adcbe24": { "message": "リトアニア語" },
  "loading_25990131": { "message": "読み込み中・・・" },
  "macedonian_6ed541af": { "message": "マケドニア語" },
  "malay_f5dddce4": { "message": "マレー語" },
  "maltese_916925e8": { "message": "マルタ語" },
  "maori_new_zealand_5380a95f": { "message": "マオリ語 (ニュージーランド)" },
  "no_preview_is_available_for_this_file_f940114a": {
    "message": "このファイルでは、プレビューは利用できません。"
  },
  "norwegian_53f391ec": { "message": "ノルウェー語" },
  "norwegian_bokmal_ad5843fa": { "message": "ノルウェー語（Bokmål）" },
  "norwegian_nynorsk_c785f8a6": { "message": "ノルウェー語（Nynorsk）" },
  "persian_a8cadb95": { "message": "ペルシャ語" },
  "polish_4cf2ecaf": { "message": "ポーランド語" },
  "portuguese_9c212cf4": { "message": "ポルトガル語" },
  "romanian_13670c1e": { "message": "ルーマニア語" },
  "russian_1e3e197": { "message": "ロシア語" },
  "serbian_7187f1f2": { "message": "セルビア語" },
  "slovak_69f48e1b": { "message": "スロバキア語" },
  "slovenian_30ae5208": { "message": "スロベニア語" },
  "spanish_de9de5d6": { "message": "スペイン語" },
  "swahili_5caeb4ba": { "message": "スワヒリ語" },
  "swedish_59a593ca": { "message": "スウェーデン語" },
  "tagalog_74906db7": { "message": "タガログ語" },
  "thai_8f9bc548": { "message": "タイ語" },
  "the_selected_file_exceeds_the_maxsize_byte_limit_f7e8c771": {
    "message": "選択されたファイルは、{ maxSize }バイト数制限を越えています"
  },
  "turkish_5b69578b": { "message": "トルコ語" },
  "ukrainian_945b00b7": { "message": "ウクライナ語" },
  "vietnamese_e7a76583": { "message": "ベトナム語" },
  "welsh_42ab94b1": { "message": "ウェールズ語" },
  "yiddish_f96986df": { "message": "イディッシュ語" },
  "you_can_replace_by_uploading_a_new_caption_file_6c88ce00": {
    "message": "新しいキャプションファイルをアップロードすることで置換することができます。"
  }
}


formatMessage.addLocale({ja: locale})
