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
import formatMessage from 'format-message'

const closedCaptionLanguages = [
  {
    id: 'af',
    label: formatMessage('Afrikaans'),
  },
  {
    id: 'sq',
    label: formatMessage('Albanian'),
  },
  {
    id: 'ar',
    label: formatMessage('Arabic'),
  },
  {
    id: 'be',
    label: formatMessage('Belarusian'),
  },
  {
    id: 'bg',
    label: formatMessage('Bulgarian'),
  },
  {
    id: 'ca',
    label: formatMessage('Catalan'),
  },
  {
    id: 'zh',
    label: formatMessage('Chinese'),
  },
  {
    id: 'hr',
    label: formatMessage('Croatian'),
  },
  {
    id: 'cs',
    label: formatMessage('Czech'),
  },
  {
    id: 'da',
    label: formatMessage('Danish'),
  },
  {
    id: 'nl',
    label: formatMessage('Dutch'),
  },
  {
    id: 'en',
    label: formatMessage('English'),
  },
  {
    id: 'et',
    label: formatMessage('Estonian'),
  },
  {
    id: 'fl',
    label: formatMessage('Filipino'),
  },
  {
    id: 'fi',
    label: formatMessage('Finnish'),
  },
  {
    id: 'fr',
    label: formatMessage('French'),
  },
  {
    id: 'gl',
    label: formatMessage('Galician'),
  },
  {
    id: 'de',
    label: formatMessage('German'),
  },
  {
    id: 'el',
    label: formatMessage('Greek'),
  },
  {
    id: 'ht',
    label: formatMessage('Haitian Creole'),
  },
  {
    id: 'hi',
    label: formatMessage('Hindi'),
  },
  {
    id: 'hu',
    label: formatMessage('Hungarian'),
  },
  {
    id: 'is',
    label: formatMessage('Icelandic'),
  },
  {
    id: 'id',
    label: formatMessage('Indonesian'),
  },
  {
    id: 'ga',
    label: formatMessage('Irish'),
  },
  {
    id: 'it',
    label: formatMessage('Italian'),
  },
  {
    id: 'ja',
    label: formatMessage('Japanese'),
  },
  {
    id: 'ko',
    label: formatMessage('Korean'),
  },
  {
    id: 'lv',
    label: formatMessage('Latvian'),
  },
  {
    id: 'lt',
    label: formatMessage('Lithuanian'),
  },
  {
    id: 'mk',
    label: formatMessage('Macedonian'),
  },
  {
    id: 'ms',
    label: formatMessage('Malay'),
  },
  {
    id: 'mt',
    label: formatMessage('Maltese'),
  },
  {
    id: 'no',
    label: formatMessage('Norwegian'),
  },
  {
    id: 'fa',
    label: formatMessage('Persian'),
  },
  {
    id: 'pl',
    label: formatMessage('Polish'),
  },
  {
    id: 'pt',
    label: formatMessage('Portuguese'),
  },
  {
    id: 'ro',
    label: formatMessage('Romanian'),
  },
  {
    id: 'ru',
    label: formatMessage('Russian'),
  },
  {
    id: 'sr',
    label: formatMessage('Serbian'),
  },
  {
    id: 'sk',
    label: formatMessage('Slovak'),
  },
  {
    id: 'sl',
    label: formatMessage('Slovenian'),
  },
  {
    id: 'es',
    label: formatMessage('Spanish'),
  },
  {
    id: 'sw',
    label: formatMessage('Swahili'),
  },
  {
    id: 'sv',
    label: formatMessage('Swedish'),
  },
  {
    id: 'tl',
    label: formatMessage('Tagalog'),
  },
  {
    id: 'th',
    label: formatMessage('Thai'),
  },
  {
    id: 'tr',
    label: formatMessage('Turkish'),
  },
  {
    id: 'uk',
    label: formatMessage('Ukrainian'),
  },
  {
    id: 'vi',
    label: formatMessage('Vietnamese'),
  },
  {
    id: 'cy',
    label: formatMessage('Welsh'),
  },
  {
    id: 'yi',
    label: formatMessage('Yiddish'),
  },
  {
    id: 'en-CA',
    label: formatMessage('English (Canada)'),
  },
  // added when we expanded CC languages to all
  // those supported in canvas
  {
    id: 'en-AU',
    label: formatMessage('English (Australia)'),
  },
  {
    id: 'en-GB',
    label: formatMessage('English (United Kingdom)'),
  },
  {
    id: 'fr-CA',
    label: formatMessage('French (Canada)'),
  },
  {
    id: 'he',
    label: formatMessage('Hebrew'),
  },
  {
    id: 'hy',
    label: formatMessage('Armenian'),
  },
  {
    id: 'mi',
    label: formatMessage('Māori (New Zealand)'),
  },
  {
    id: 'nb',
    label: formatMessage('Norwegian Bokmål'),
  },
  {
    id: 'nn',
    label: formatMessage('Norwegian Nynorsk'),
  },
  {
    id: 'zh-Hans',
    label: formatMessage('Chinese Simplified'),
  },
  {
    id: 'zh-Hant',
    label: formatMessage('Chinese Traditional'),
  },
]

function sortedClosedCaptionLanguageList(userLocale) {
  const ul = userLocale.replace('_', '-')
  const langlist = closedCaptionLanguages.sort((a, b) => {
    if (a.id === ul) {
      return -1
    } else if (b.id === ul) {
      return 1
    } else {
      return a.label.localeCompare(b.label, ul)
    }
  })
  return langlist
}

export {sortedClosedCaptionLanguageList, closedCaptionLanguages as default}
