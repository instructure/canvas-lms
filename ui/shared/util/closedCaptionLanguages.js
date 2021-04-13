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
import I18n from 'i18n!closedCaptionLanguages'

const closedCaptionLanguages = {
  get af() {
    return I18n.t('Afrikaans')
  },
  get sq() {
    return I18n.t('Albanian')
  },
  get ar() {
    return I18n.t('Arabic')
  },
  get be() {
    return I18n.t('Belarusian')
  },
  get bg() {
    return I18n.t('Bulgarian')
  },
  get ca() {
    return I18n.t('Catalan')
  },
  get zh() {
    return I18n.t('Chinese')
  },
  get 'zh-cn'() {
    return I18n.t('Chinese Simplified')
  },
  get 'zh-tw'() {
    return I18n.t('Chinese Traditional')
  },
  get hr() {
    return I18n.t('Croatian')
  },
  get cs() {
    return I18n.t('Czech')
  },
  get da() {
    return I18n.t('Danish')
  },
  get nl() {
    return I18n.t('Dutch')
  },
  get en() {
    return I18n.t('English')
  },
  get et() {
    return I18n.t('Estonian')
  },
  get fl() {
    return I18n.t('Filipino')
  },
  get fi() {
    return I18n.t('Finnish')
  },
  get fr() {
    return I18n.t('French')
  },
  get gl() {
    return I18n.t('Galician')
  },
  get de() {
    return I18n.t('German')
  },
  get el() {
    return I18n.t('Greek')
  },
  get ht() {
    return I18n.t('Haitian Creole')
  },
  get iw() {
    return I18n.t('Hebrew')
  },
  get hi() {
    return I18n.t('Hindi')
  },
  get hu() {
    return I18n.t('Hungarian')
  },
  get is() {
    return I18n.t('Icelandic')
  },
  get id() {
    return I18n.t('Indonesian')
  },
  get ga() {
    return I18n.t('Irish')
  },
  get it() {
    return I18n.t('Italian')
  },
  get ja() {
    return I18n.t('Japanese')
  },
  get ko() {
    return I18n.t('Korean')
  },
  get lv() {
    return I18n.t('Latvian')
  },
  get lt() {
    return I18n.t('Lithuanian')
  },
  get mk() {
    return I18n.t('Macedonian')
  },
  get ms() {
    return I18n.t('Malay')
  },
  get mt() {
    return I18n.t('Maltese')
  },
  get no() {
    return I18n.t('Norwegian')
  },
  get fa() {
    return I18n.t('Persian')
  },
  get pl() {
    return I18n.t('Polish')
  },
  get pt() {
    return I18n.t('Portuguese')
  },
  get ro() {
    return I18n.t('Romanian')
  },
  get ru() {
    return I18n.t('Russian')
  },
  get sr() {
    return I18n.t('Serbian')
  },
  get sk() {
    return I18n.t('Slovak')
  },
  get sl() {
    return I18n.t('Slovenian')
  },
  get es() {
    return I18n.t('Spanish')
  },
  get sw() {
    return I18n.t('Swahili')
  },
  get sv() {
    return I18n.t('Swedish')
  },
  get tl() {
    return I18n.t('Tagalog')
  },
  get th() {
    return I18n.t('Thai')
  },
  get tr() {
    return I18n.t('Turkish')
  },
  get uk() {
    return I18n.t('Ukrainian')
  },
  get vi() {
    return I18n.t('Vietnamese')
  },
  get cy() {
    return I18n.t('Welsh')
  },
  get yi() {
    return I18n.t('Yiddish')
  }
}

if (ENV.FEATURES?.expand_cc_languages) {
  Object.defineProperties(closedCaptionLanguages, {
    'en-CA': {
      configurable: false,
      enumerable: true,
      get() {
        return I18n.t('English (Canada)')
      }
    },
    'en-AU': {
      configurable: false,
      enumerable: true,
      get() {
        return I18n.t('English (Australia)')
      }
    },
    'en-GB': {
      configurable: false,
      enumerable: true,
      get() {
        return I18n.t('English (United Kingdom)')
      }
    },
    'fr-CA': {
      configurable: false,
      enumerable: true,
      get() {
        return I18n.t('French (Canada)')
      }
    },
    he: {
      configurable: false,
      enumerable: true,
      get() {
        return I18n.t('Hebrew')
      }
    },
    hy: {
      configurable: false,
      enumerable: true,
      get() {
        return I18n.t('Armenian')
      }
    },
    mi: {
      configurable: false,
      enumerable: true,
      get() {
        return I18n.t('Māori (New Zealand)')
      }
    },
    nb: {
      configurable: false,
      enumerable: true,
      get() {
        return I18n.t('Norwegian Bokmål')
      }
    },
    nn: {
      configurable: false,
      enumerable: true,
      get() {
        return I18n.t('Norwegian Nynorsk')
      }
    },
    'zh-Hans': {
      configurable: false,
      enumerable: true,
      get() {
        return I18n.t('Chinese Simplified')
      }
    },
    'zh-Hant': {
      configurable: false,
      enumerable: true,
      get() {
        return I18n.t('Chinese Traditional')
      }
    }
  })
  delete closedCaptionLanguages['zh-cn']
  delete closedCaptionLanguages['zh-tw']
  delete closedCaptionLanguages.iw
}

export default closedCaptionLanguages
