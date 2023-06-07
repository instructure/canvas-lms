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
import formatMessage from './format-message'

const closedCaptionLanguages = [
  {
    id: 'af',
    get label() {
      return formatMessage('Afrikaans')
    },
  },
  {
    id: 'sq',
    get label() {
      return formatMessage('Albanian')
    },
  },
  {
    id: 'ar',
    get label() {
      return formatMessage('Arabic')
    },
  },
  {
    id: 'be',
    get label() {
      return formatMessage('Belarusian')
    },
  },
  {
    id: 'bg',
    get label() {
      return formatMessage('Bulgarian')
    },
  },
  {
    id: 'ca',
    get label() {
      return formatMessage('Catalan')
    },
  },
  {
    id: 'zh',
    get label() {
      return formatMessage('Chinese')
    },
  },
  {
    id: 'hr',
    get label() {
      return formatMessage('Croatian')
    },
  },
  {
    id: 'cs',
    get label() {
      return formatMessage('Czech')
    },
  },
  {
    id: 'da',
    get label() {
      return formatMessage('Danish')
    },
  },
  {
    id: 'nl',
    get label() {
      return formatMessage('Dutch')
    },
  },
  {
    id: 'en',
    get label() {
      return formatMessage('English')
    },
  },
  {
    id: 'et',
    get label() {
      return formatMessage('Estonian')
    },
  },
  {
    id: 'fl',
    get label() {
      return formatMessage('Filipino')
    },
  },
  {
    id: 'fi',
    get label() {
      return formatMessage('Finnish')
    },
  },
  {
    id: 'fr',
    get label() {
      return formatMessage('French')
    },
  },
  {
    id: 'gl',
    get label() {
      return formatMessage('Galician')
    },
  },
  {
    id: 'de',
    get label() {
      return formatMessage('German')
    },
  },
  {
    id: 'el',
    get label() {
      return formatMessage('Greek')
    },
  },
  {
    id: 'ht',
    get label() {
      return formatMessage('Haitian Creole')
    },
  },
  {
    id: 'hi',
    get label() {
      return formatMessage('Hindi')
    },
  },
  {
    id: 'hu',
    get label() {
      return formatMessage('Hungarian')
    },
  },
  {
    id: 'is',
    get label() {
      return formatMessage('Icelandic')
    },
  },
  {
    id: 'id',
    get label() {
      return formatMessage('Indonesian')
    },
  },
  {
    id: 'ga',
    get label() {
      return formatMessage('Irish')
    },
  },
  {
    id: 'it',
    get label() {
      return formatMessage('Italian')
    },
  },
  {
    id: 'ja',
    get label() {
      return formatMessage('Japanese')
    },
  },
  {
    id: 'ko',
    get label() {
      return formatMessage('Korean')
    },
  },
  {
    id: 'lv',
    get label() {
      return formatMessage('Latvian')
    },
  },
  {
    id: 'lt',
    get label() {
      return formatMessage('Lithuanian')
    },
  },
  {
    id: 'mk',
    get label() {
      return formatMessage('Macedonian')
    },
  },
  {
    id: 'ms',
    get label() {
      return formatMessage('Malay')
    },
  },
  {
    id: 'mt',
    get label() {
      return formatMessage('Maltese')
    },
  },
  {
    id: 'no',
    get label() {
      return formatMessage('Norwegian')
    },
  },
  {
    id: 'fa',
    get label() {
      return formatMessage('Persian')
    },
  },
  {
    id: 'pl',
    get label() {
      return formatMessage('Polish')
    },
  },
  {
    id: 'pt',
    get label() {
      return formatMessage('Portuguese')
    },
  },
  {
    id: 'ro',
    get label() {
      return formatMessage('Romanian')
    },
  },
  {
    id: 'ru',
    get label() {
      return formatMessage('Russian')
    },
  },
  {
    id: 'sr',
    get label() {
      return formatMessage('Serbian')
    },
  },
  {
    id: 'sk',
    get label() {
      return formatMessage('Slovak')
    },
  },
  {
    id: 'sl',
    get label() {
      return formatMessage('Slovenian')
    },
  },
  {
    id: 'es',
    get label() {
      return formatMessage('Spanish')
    },
  },
  {
    id: 'sw',
    get label() {
      return formatMessage('Swahili')
    },
  },
  {
    id: 'sv',
    get label() {
      return formatMessage('Swedish')
    },
  },
  {
    id: 'tl',
    get label() {
      return formatMessage('Tagalog')
    },
  },
  {
    id: 'th',
    get label() {
      return formatMessage('Thai')
    },
  },
  {
    id: 'tr',
    get label() {
      return formatMessage('Turkish')
    },
  },
  {
    id: 'uk',
    get label() {
      return formatMessage('Ukrainian')
    },
  },
  {
    id: 'vi',
    get label() {
      return formatMessage('Vietnamese')
    },
  },
  {
    id: 'cy',
    get label() {
      return formatMessage('Welsh')
    },
  },
  {
    id: 'yi',
    get label() {
      return formatMessage('Yiddish')
    },
  },
  {
    id: 'en-CA',
    get label() {
      return formatMessage('English (Canada)')
    },
  },
  // added when we expanded CC languages to all
  // those supported in canvas
  {
    id: 'en-AU',
    get label() {
      return formatMessage('English (Australia)')
    },
  },
  {
    id: 'en-GB',
    get label() {
      return formatMessage('English (United Kingdom)')
    },
  },
  {
    id: 'fr-CA',
    get label() {
      return formatMessage('French (Canada)')
    },
  },
  {
    id: 'he',
    get label() {
      return formatMessage('Hebrew')
    },
  },
  {
    id: 'hy',
    get label() {
      return formatMessage('Armenian')
    },
  },
  {
    id: 'mi',
    get label() {
      return formatMessage('Māori (New Zealand)')
    },
  },
  {
    id: 'nb',
    get label() {
      return formatMessage('Norwegian Bokmål')
    },
  },
  {
    id: 'nn',
    get label() {
      return formatMessage('Norwegian Nynorsk')
    },
  },
  {
    id: 'zh-Hans',
    get label() {
      return formatMessage('Chinese Simplified')
    },
  },
  {
    id: 'zh-Hant',
    get label() {
      return formatMessage('Chinese Traditional')
    },
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

function captionLanguageForLocale(locale) {
  return closedCaptionLanguages.find(lang => lang.id === locale)?.label || locale
}

export {
  sortedClosedCaptionLanguageList,
  captionLanguageForLocale,
  closedCaptionLanguages as default,
}
