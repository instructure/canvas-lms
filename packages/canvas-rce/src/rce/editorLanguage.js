/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

// if a locale is absent, we don't expect to receive it from canvas, but we'll
// treat it the same as how we explicitly use english for Maori.
const mapping = {
  ar: 'ar_SA',
  bg: 'bg_BG',
  ca: 'ca',
  cs: 'cs',
  cy: 'cy',
  da: 'da',
  de: 'de',
  el: 'el',
  // returning undefined tell tinymce to use it's default (en) strings
  en: undefined,
  // tinymce doesn't have Australian strings, so just pretend it's en-GB
  'en-AU': 'en_GB',
  'en-GB': 'en_GB',
  es: 'es',
  'es-ES': 'es',
  fa: 'fa_IR',
  'fa-IR': 'fa_IR',
  fi: 'fi',
  fr: 'fr_FR',
  'fr-CA': 'fr_FR',
  ga: 'ga',
  he: 'he_IL',
  ht: undefined, // tiny doesn't have Haitian Creole
  hu: 'hu_HU',
  hy: 'hy',
  id: 'id',
  is: undefined, // tiny doesn't have Icelandic
  it: 'it',
  ja: 'ja',
  ko: 'ko_KR',
  mi: undefined,
  ms: undefined, // tiny has Malayalam but not Malay Standard, haiyaa
  nb: 'nb_NO',
  nl: 'nl',
  nn: 'nb_NO', // tiny doesn't have Norwegian (Nynorsk) so go to Norwegian (Bokmal)
  pl: 'pl',
  pt: 'pt_PT',
  'pt-BR': 'pt_BR',
  ro: 'ro',
  ru: 'ru',
  sq: undefined, // tiny doesn't have Albanian
  sr: 'sr',
  sl: 'sl',
  sv: 'sv_SE',
  th: 'th',
  tr: 'tr_TR',
  'uk-UA': 'uk_UA',
  uk: 'uk_UA',
  vi: 'vi_VN',
  zh: 'zh_CN',
  'zh-HK': 'zh_TW',
  'zh-Hans': 'zh_CN',
  'zh-Hant': 'zh_TW',
}

// still expose it as a method for consistent usage and in case we ever have to
// add special casing or null interpretation in the future
function editorLanguage(locale) {
  if (!locale) {
    return mapping.en
  }
  if (locale.match('_')) {
    locale = locale.replace('_', '-')
  }
  // tinymce won't know about custom locales, use the base one for mapping
  if (locale.match('-x-')) {
    locale = locale.split('-x-')[0]
  }
  if (mapping[locale]) {
    return mapping[locale]
  }
  return mapping[locale.split('-')[0]]
}

module.exports = editorLanguage
