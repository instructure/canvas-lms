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
  "afrikaans_da0fe6ee": { "message": "Afrikaans" },
  "albanian_21ed929e": { "message": "Albanese" },
  "arabic_c5c87acd": { "message": "Arabo" },
  "armenian_12da6118": { "message": "Armeno" },
  "belarusian_b2f19c76": { "message": "Bielorusso" },
  "bulgarian_feccab7e": { "message": "Bulgaro" },
  "captions_inherited_from_a_parent_course_cannot_be__9248fa3a": {
    "message": "Impossibile eliminare i sottotitoli ereditati da un corso principale."
  },
  "catalan_16f6b78f": { "message": "Catalano" },
  "chinese_111d37f6": { "message": "Cinese" },
  "chinese_simplified_7f0bd370": { "message": "Cinese semplificato" },
  "chinese_traditional_8a7f759d": { "message": "Cinese tradizionale" },
  "croatian_d713d655": { "message": "Croato" },
  "czech_9aa2cbe4": { "message": "Ceco" },
  "danish_c18cdac8": { "message": "Danese" },
  "dutch_6d05cee5": { "message": "Olandese" },
  "english_australia_dc405d82": { "message": "Inglese (Australia)" },
  "english_c60612e2": { "message": "Inglese" },
  "english_canada_12688ee4": { "message": "Inglese (Canada)" },
  "english_united_kingdom_a613f831": { "message": "Inglese (Regno Unito)" },
  "estonian_5e8e2fa4": { "message": "Estone" },
  "file_name_8fd421ff": { "message": "Nome file" },
  "filipino_33339264": { "message": "Filippino" },
  "finnish_4df2923d": { "message": "Finlandese" },
  "french_33881544": { "message": "Francese" },
  "french_canada_c3d92fa6": { "message": "Francese (Canada)" },
  "galician_7e4508b5": { "message": "Galiziano" },
  "german_3ec99bbb": { "message": "Tedesco" },
  "greek_65c5b3f7": { "message": "Greco" },
  "haitian_creole_7eb4195b": { "message": "Creolo haitiano" },
  "hebrew_88fbf778": { "message": "Ebraico" },
  "hindi_9bcd4b34": { "message": "Hindi" },
  "hungarian_fc7d30c9": { "message": "Ungherese" },
  "icelandic_9d6d35de": { "message": "Islandese" },
  "indonesian_5f6accd6": { "message": "Indonesiano" },
  "irish_567e109f": { "message": "Irlandese" },
  "italian_bd3c792d": { "message": "Italiano" },
  "japanese_b5721ca7": { "message": "Giapponese" },
  "korean_da812d9": { "message": "Coreano" },
  "latvian_2bbb6aab": { "message": "Lettone" },
  "lithuanian_5adcbe24": { "message": "Lituano" },
  "loading_25990131": { "message": "Caricamento in corso..." },
  "macedonian_6ed541af": { "message": "Macedone" },
  "malay_f5dddce4": { "message": "Malese" },
  "maltese_916925e8": { "message": "Maltese" },
  "maori_new_zealand_5380a95f": { "message": "Māori (Nuova Zelanda)" },
  "no_preview_is_available_for_this_file_f940114a": {
    "message": "Nessuna anteprima disponibile per questo file."
  },
  "norwegian_53f391ec": { "message": "Norvegese" },
  "norwegian_bokmal_ad5843fa": { "message": "Bokmål norvegese" },
  "norwegian_nynorsk_c785f8a6": { "message": "Nynorsk norvegese" },
  "persian_a8cadb95": { "message": "Persiano" },
  "polish_4cf2ecaf": { "message": "Polacco" },
  "portuguese_9c212cf4": { "message": "Portoghese" },
  "romanian_13670c1e": { "message": "Rumeno" },
  "russian_1e3e197": { "message": "Russo" },
  "serbian_7187f1f2": { "message": "Serbo" },
  "slovak_69f48e1b": { "message": "Slovacco" },
  "slovenian_30ae5208": { "message": "Sloveno" },
  "spanish_de9de5d6": { "message": "Spagnolo" },
  "swahili_5caeb4ba": { "message": "Swahili" },
  "swedish_59a593ca": { "message": "Svedese" },
  "tagalog_74906db7": { "message": "Tagalog" },
  "thai_8f9bc548": { "message": "Tailandese" },
  "the_selected_file_exceeds_the_maxsize_byte_limit_f7e8c771": {
    "message": "Il file selezionato supera il limite di { maxSize } byte"
  },
  "turkish_5b69578b": { "message": "Turco" },
  "ukrainian_945b00b7": { "message": "Ucraino" },
  "vietnamese_e7a76583": { "message": "Vietnamita" },
  "welsh_42ab94b1": { "message": "Gallese" },
  "yiddish_f96986df": { "message": "Yiddish" },
  "you_can_replace_by_uploading_a_new_caption_file_6c88ce00": {
    "message": "Puoi sostituirli caricando un nuovo file dei sottotitoli."
  }
}


formatMessage.addLocale({it: locale})
