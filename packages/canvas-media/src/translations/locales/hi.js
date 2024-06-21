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
  "afrikaans_da0fe6ee": { "message": "अफ़्रीकी" },
  "albanian_21ed929e": { "message": "अल्बानियाई" },
  "arabic_c5c87acd": { "message": "अरबी" },
  "armenian_12da6118": { "message": "अर्मेनियाई" },
  "belarusian_b2f19c76": { "message": "बेलारूसी" },
  "bulgarian_feccab7e": { "message": "बल्गेरियाई" },
  "captions_inherited_from_a_parent_course_cannot_be__9248fa3a": {
    "message": "मूल पाठ्यक्रम से प्राप्त कैप्शन को हटाया नहीं जा सकता।"
  },
  "catalan_16f6b78f": { "message": "कैटलन" },
  "chinese_111d37f6": { "message": "चीनी" },
  "chinese_simplified_7f0bd370": { "message": "चीनी सरलीकृत" },
  "chinese_traditional_8a7f759d": { "message": "चीनी पारंपरिक" },
  "croatian_d713d655": { "message": "क्रोएशियाई" },
  "czech_9aa2cbe4": { "message": "चेक" },
  "danish_c18cdac8": { "message": "डेनिश" },
  "dutch_6d05cee5": { "message": "डच" },
  "english_australia_dc405d82": { "message": "अंग्रेज़ी (ऑस्ट्रेलिया)" },
  "english_c60612e2": { "message": "अंग्रेज़ी" },
  "english_canada_12688ee4": { "message": "अंग्रेज़ी (कनाडा)" },
  "english_united_kingdom_a613f831": {
    "message": "अंग्रेज़ी (यूनाइटेड किंगडम)"
  },
  "estonian_5e8e2fa4": { "message": "एस्टोनियाई" },
  "file_name_8fd421ff": { "message": "फ़ाइल नाम" },
  "filipino_33339264": { "message": "फ़िलिपिनो" },
  "finnish_4df2923d": { "message": "फ़िनिश" },
  "french_33881544": { "message": "फ़्रेंच" },
  "french_canada_c3d92fa6": { "message": "फ़्रेंच (कनाडा)" },
  "galician_7e4508b5": { "message": "गैलिशियन" },
  "german_3ec99bbb": { "message": "जर्मन" },
  "greek_65c5b3f7": { "message": "ग्रीक" },
  "haitian_creole_7eb4195b": { "message": "हैतीयन क्रियोल" },
  "hebrew_88fbf778": { "message": "हिब्रू" },
  "hindi_9bcd4b34": { "message": "हिंदी" },
  "hungarian_fc7d30c9": { "message": "हंगेरियाई" },
  "icelandic_9d6d35de": { "message": "आइसलैंडिक" },
  "indonesian_5f6accd6": { "message": "इंडोनेशियाई" },
  "irish_567e109f": { "message": "आइरिश" },
  "italian_bd3c792d": { "message": "इतालवी" },
  "japanese_b5721ca7": { "message": "जापानी" },
  "korean_da812d9": { "message": "कोरियाई" },
  "latvian_2bbb6aab": { "message": "लातवियाई" },
  "lithuanian_5adcbe24": { "message": "लिथुआनियाई" },
  "loading_25990131": { "message": "लोड किया जा रहा है..." },
  "macedonian_6ed541af": { "message": "मेसीडोनियाई" },
  "malay_f5dddce4": { "message": "मलय" },
  "maltese_916925e8": { "message": "माल्टीज़" },
  "maori_new_zealand_5380a95f": { "message": "माओरी (न्यूज़ीलैंड)" },
  "no_preview_is_available_for_this_file_f940114a": {
    "message": "इस फ़ाइल के लिए कोई पूर्वावलोकन उपलब्ध नहीं है।"
  },
  "norwegian_53f391ec": { "message": "नॉर्वेजियन" },
  "norwegian_bokmal_ad5843fa": { "message": "नॉर्वेजियन बोकमाल" },
  "norwegian_nynorsk_c785f8a6": { "message": "नॉर्वेजियन नाइनोर्स्क" },
  "persian_a8cadb95": { "message": "फ़ारसी" },
  "polish_4cf2ecaf": { "message": "पोलिश" },
  "portuguese_9c212cf4": { "message": "पुर्तगाली" },
  "romanian_13670c1e": { "message": "रोमानियाई" },
  "russian_1e3e197": { "message": "रूसी" },
  "serbian_7187f1f2": { "message": "सर्बियाई" },
  "slovak_69f48e1b": { "message": "स्लोवाक" },
  "slovenian_30ae5208": { "message": "स्लोवेनियाई" },
  "spanish_de9de5d6": { "message": "स्पैनिश" },
  "swahili_5caeb4ba": { "message": "स्वाहिली" },
  "swedish_59a593ca": { "message": "स्वीडिश" },
  "tagalog_74906db7": { "message": "टगालॉग" },
  "thai_8f9bc548": { "message": "थाई" },
  "the_selected_file_exceeds_the_maxsize_byte_limit_f7e8c771": {
    "message": "चयनित फ़ाइल { maxSize } बाइट सीमा से अधिक है"
  },
  "turkish_5b69578b": { "message": "तुर्की" },
  "ukrainian_945b00b7": { "message": "यूक्रेनी" },
  "vietnamese_e7a76583": { "message": "वियतनामी" },
  "welsh_42ab94b1": { "message": "वेल्श" },
  "yiddish_f96986df": { "message": "यहूदी" },
  "you_can_replace_by_uploading_a_new_caption_file_6c88ce00": {
    "message": "आप नई कैप्शन फ़ाइल अपलोड करके प्रतिस्थापित कर सकते हैं।"
  }
}


formatMessage.addLocale({hi: locale})
