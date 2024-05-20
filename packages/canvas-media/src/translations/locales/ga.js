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
  "afrikaans_da0fe6ee": { "message": "Afracáinis" },
  "albanian_21ed929e": { "message": "Albáinise" },
  "arabic_c5c87acd": { "message": "Araibis" },
  "armenian_12da6118": { "message": "Airméinis" },
  "belarusian_b2f19c76": { "message": "Bealarúisis" },
  "bulgarian_feccab7e": { "message": "Bulgáiris" },
  "captions_inherited_from_a_parent_course_cannot_be__9248fa3a": {
    "message": "Ní féidir fotheidil a fuarthas mar oidhreacht ó chúrsa tuismitheora a bhaint."
  },
  "catalan_16f6b78f": { "message": "Catalóinis" },
  "chinese_111d37f6": { "message": "Síneach" },
  "chinese_simplified_7f0bd370": { "message": "Sínis Simplithe" },
  "chinese_traditional_8a7f759d": { "message": "Sínis Traidisiúnta" },
  "croatian_d713d655": { "message": "Cróitis" },
  "czech_9aa2cbe4": { "message": "Seiceach" },
  "danish_c18cdac8": { "message": "Danmhairgis" },
  "dutch_6d05cee5": { "message": "Ollainnis" },
  "english_australia_dc405d82": { "message": "Béarla (An Astráil)" },
  "english_c60612e2": { "message": "Béarla" },
  "english_canada_12688ee4": { "message": "Béarla (Ceanada)" },
  "english_united_kingdom_a613f831": {
    "message": "Béarla (An Ríocht Aontaithe)"
  },
  "estonian_5e8e2fa4": { "message": "Eastóinis" },
  "file_name_8fd421ff": { "message": "Ainm comhaid" },
  "filipino_33339264": { "message": "Filipíneach" },
  "finnish_4df2923d": { "message": "Fionlainnis" },
  "french_33881544": { "message": "Fraincis" },
  "french_canada_c3d92fa6": { "message": "Fraincis (Ceanada)" },
  "galician_7e4508b5": { "message": "Gailísis" },
  "german_3ec99bbb": { "message": "Gearmáinis" },
  "greek_65c5b3f7": { "message": "Gréigis" },
  "haitian_creole_7eb4195b": { "message": "Criól Haiti" },
  "hebrew_88fbf778": { "message": "Eabhrais" },
  "hindi_9bcd4b34": { "message": "Hiondúis" },
  "hungarian_fc7d30c9": { "message": "Ungáiris" },
  "icelandic_9d6d35de": { "message": "Íoslainnis" },
  "indonesian_5f6accd6": { "message": "Indinéisis" },
  "irish_567e109f": { "message": "Gaeilge" },
  "italian_bd3c792d": { "message": "Iodáilise" },
  "japanese_b5721ca7": { "message": "Seapáinise" },
  "korean_da812d9": { "message": "Cóiréis" },
  "latvian_2bbb6aab": { "message": "Laitvise" },
  "lithuanian_5adcbe24": { "message": "Liotuáinis" },
  "loading_25990131": { "message": "Ag lódáil..." },
  "macedonian_6ed541af": { "message": "Macadóinise" },
  "malay_f5dddce4": { "message": "Malaeise" },
  "maltese_916925e8": { "message": "Máltaise" },
  "maori_new_zealand_5380a95f": { "message": "Māori (An Nua-Shéalainn)" },
  "no_preview_is_available_for_this_file_f940114a": {
    "message": "Níl réamhamharc ar fáil don chomhad seo."
  },
  "norwegian_53f391ec": { "message": "Ioruaise" },
  "norwegian_bokmal_ad5843fa": { "message": "Bokmål Ioruaise" },
  "norwegian_nynorsk_c785f8a6": { "message": "Nynorsk Ioruaise" },
  "persian_a8cadb95": { "message": "Peirsise" },
  "polish_4cf2ecaf": { "message": "Polainnis" },
  "portuguese_9c212cf4": { "message": "Portaingéilis" },
  "romanian_13670c1e": { "message": "Rómáinise" },
  "russian_1e3e197": { "message": "Rúisis" },
  "serbian_7187f1f2": { "message": "Seirbise" },
  "slovak_69f48e1b": { "message": "Slóvaicise" },
  "slovenian_30ae5208": { "message": "Slóivéinise" },
  "spanish_de9de5d6": { "message": "Spáinnise" },
  "swahili_5caeb4ba": { "message": "Svahaílis" },
  "swedish_59a593ca": { "message": "Sualainnise" },
  "tagalog_74906db7": { "message": "Tagálaigis" },
  "thai_8f9bc548": { "message": "Téalainnis" },
  "the_selected_file_exceeds_the_maxsize_byte_limit_f7e8c771": {
    "message": "Sáraíonn an comhad roghnaithe an teorainn { maxSize } Beart"
  },
  "turkish_5b69578b": { "message": "Tuircis" },
  "ukrainian_945b00b7": { "message": "Úcráinise" },
  "vietnamese_e7a76583": { "message": "Vítneaimis" },
  "welsh_42ab94b1": { "message": "Breatnaise" },
  "yiddish_f96986df": { "message": "Giúdais" },
  "you_can_replace_by_uploading_a_new_caption_file_6c88ce00": {
    "message": "Is féidir leat comhad é ionadú trí cheannteidil nua a uaslódáil"
  }
}


formatMessage.addLocale({ga: locale})
