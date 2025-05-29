/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

export default function loadLocale(locale: string) {
  switch (locale) {
    case 'moment/locale/af':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/af" */ 'moment/locale/af')

    case 'moment/locale/ar-dz':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/ar-dz" */ 'moment/locale/ar-dz')

    case 'moment/locale/ar-kw':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/ar-kw" */ 'moment/locale/ar-kw')

    case 'moment/locale/ar-ly':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/ar-ly" */ 'moment/locale/ar-ly')

    case 'moment/locale/ar-ma':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/ar-ma" */ 'moment/locale/ar-ma')

    case 'moment/locale/ar-sa':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/ar-sa" */ 'moment/locale/ar-sa')

    case 'moment/locale/ar-tn':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/ar-tn" */ 'moment/locale/ar-tn')

    case 'moment/locale/ar':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/ar" */ 'moment/locale/ar')

    case 'moment/locale/az':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/az" */ 'moment/locale/az')

    case 'moment/locale/be':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/be" */ 'moment/locale/be')

    case 'moment/locale/bg':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/bg" */ 'moment/locale/bg')

    case 'moment/locale/bm':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/bm" */ 'moment/locale/bm')

    case 'moment/locale/bn-bd':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/bn-bd" */ 'moment/locale/bn-bd')

    case 'moment/locale/bn':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/bn" */ 'moment/locale/bn')

    case 'moment/locale/bo':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/bo" */ 'moment/locale/bo')

    case 'moment/locale/br':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/br" */ 'moment/locale/br')

    case 'moment/locale/bs':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/bs" */ 'moment/locale/bs')

    case 'moment/locale/cs':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/cs" */ 'moment/locale/cs')

    case 'moment/locale/cv':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/cv" */ 'moment/locale/cv')

    case 'moment/locale/cy':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/cy" */ 'moment/locale/cy')

    case 'moment/locale/da':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/da" */ 'moment/locale/da')

    case 'moment/locale/de-at':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/de-at" */ 'moment/locale/de-at')

    case 'moment/locale/de-ch':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/de-ch" */ 'moment/locale/de-ch')

    case 'moment/locale/dv':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/dv" */ 'moment/locale/dv')

    case 'moment/locale/el':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/el" */ 'moment/locale/el')

    case 'moment/locale/en-au':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/en-au" */ 'moment/locale/en-au')

    case 'moment/locale/en-ca':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/en-ca" */ 'moment/locale/en-ca')

    case 'moment/locale/en-gb':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/en-gb" */ 'moment/locale/en-gb')

    case 'moment/locale/en-ie':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/en-ie" */ 'moment/locale/en-ie')

    case 'moment/locale/en-il':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/en-il" */ 'moment/locale/en-il')

    case 'moment/locale/en-in':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/en-in" */ 'moment/locale/en-in')

    case 'moment/locale/en-nz':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/en-nz" */ 'moment/locale/en-nz')

    case 'moment/locale/en-sg':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/en-sg" */ 'moment/locale/en-sg')

    case 'moment/locale/eo':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/eo" */ 'moment/locale/eo')

    case 'moment/locale/es-do':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/es-do" */ 'moment/locale/es-do')

    case 'moment/locale/es-mx':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/es-mx" */ 'moment/locale/es-mx')

    case 'moment/locale/es-us':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/es-us" */ 'moment/locale/es-us')

    case 'moment/locale/es':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/es" */ 'moment/locale/es')

    case 'moment/locale/et':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/et" */ 'moment/locale/et')

    case 'moment/locale/eu':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/eu" */ 'moment/locale/eu')

    case 'moment/locale/fi':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/fi" */ 'moment/locale/fi')

    case 'moment/locale/fil':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/fil" */ 'moment/locale/fil')

    case 'moment/locale/fo':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/fo" */ 'moment/locale/fo')

    case 'moment/locale/fr-ch':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/fr-ch" */ 'moment/locale/fr-ch')

    case 'moment/locale/fy':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/fy" */ 'moment/locale/fy')

    case 'moment/locale/ga':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/ga" */ 'moment/locale/ga')

    case 'moment/locale/gd':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/gd" */ 'moment/locale/gd')

    case 'moment/locale/gl':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/gl" */ 'moment/locale/gl')

    case 'moment/locale/gom-deva':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/gom-deva" */ 'moment/locale/gom-deva')

    case 'moment/locale/gom-latn':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/gom-latn" */ 'moment/locale/gom-latn')

    case 'moment/locale/gu':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/gu" */ 'moment/locale/gu')

    case 'moment/locale/hi':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/hi" */ 'moment/locale/hi')

    case 'moment/locale/hr':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/hr" */ 'moment/locale/hr')

    case 'moment/locale/hu':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/hu" */ 'moment/locale/hu')

    case 'moment/locale/id':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/id" */ 'moment/locale/id')

    case 'moment/locale/is':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/is" */ 'moment/locale/is')

    case 'moment/locale/it-ch':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/it-ch" */ 'moment/locale/it-ch')

    case 'moment/locale/it':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/it" */ 'moment/locale/it')

    case 'moment/locale/jv':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/jv" */ 'moment/locale/jv')

    case 'moment/locale/ka':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/ka" */ 'moment/locale/ka')

    case 'moment/locale/kk':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/kk" */ 'moment/locale/kk')

    case 'moment/locale/km':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/km" */ 'moment/locale/km')

    case 'moment/locale/kn':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/kn" */ 'moment/locale/kn')

    case 'moment/locale/ko':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/ko" */ 'moment/locale/ko')

    case 'moment/locale/ku':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/ku" */ 'moment/locale/ku')

    case 'moment/locale/ky':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/ky" */ 'moment/locale/ky')

    case 'moment/locale/lb':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/lb" */ 'moment/locale/lb')

    case 'moment/locale/lo':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/lo" */ 'moment/locale/lo')

    case 'moment/locale/lt':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/lt" */ 'moment/locale/lt')

    case 'moment/locale/lv':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/lv" */ 'moment/locale/lv')

    case 'moment/locale/me':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/me" */ 'moment/locale/me')

    case 'moment/locale/mi':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/mi" */ 'moment/locale/mi')

    case 'moment/locale/mk':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/mk" */ 'moment/locale/mk')

    case 'moment/locale/ml':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/ml" */ 'moment/locale/ml')

    case 'moment/locale/mn':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/mn" */ 'moment/locale/mn')

    case 'moment/locale/mr':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/mr" */ 'moment/locale/mr')

    case 'moment/locale/ms-my':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/ms-my" */ 'moment/locale/ms-my')

    case 'moment/locale/ms':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/ms" */ 'moment/locale/ms')

    case 'moment/locale/mt':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/mt" */ 'moment/locale/mt')

    case 'moment/locale/my':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/my" */ 'moment/locale/my')

    case 'moment/locale/nb':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/nb" */ 'moment/locale/nb')

    case 'moment/locale/ne':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/ne" */ 'moment/locale/ne')

    case 'moment/locale/nl-be':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/nl-be" */ 'moment/locale/nl-be')

    case 'moment/locale/nl':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/nl" */ 'moment/locale/nl')

    case 'moment/locale/nn':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/nn" */ 'moment/locale/nn')

    case 'moment/locale/oc-lnc':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/oc-lnc" */ 'moment/locale/oc-lnc')

    case 'moment/locale/pa-in':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/pa-in" */ 'moment/locale/pa-in')

    case 'moment/locale/pt-br':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/pt-br" */ 'moment/locale/pt-br')

    case 'moment/locale/pt':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/pt" */ 'moment/locale/pt')

    case 'moment/locale/ro':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/ro" */ 'moment/locale/ro')

    case 'moment/locale/ru':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/ru" */ 'moment/locale/ru')

    case 'moment/locale/sd':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/sd" */ 'moment/locale/sd')

    case 'moment/locale/se':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/se" */ 'moment/locale/se')

    case 'moment/locale/si':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/si" */ 'moment/locale/si')

    case 'moment/locale/sk':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/sk" */ 'moment/locale/sk')

    case 'moment/locale/sq':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/sq" */ 'moment/locale/sq')

    case 'moment/locale/sr-cyrl':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/sr-cyrl" */ 'moment/locale/sr-cyrl')

    case 'moment/locale/sr':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/sr" */ 'moment/locale/sr')

    case 'moment/locale/ss':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/ss" */ 'moment/locale/ss')

    case 'moment/locale/sv':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/sv" */ 'moment/locale/sv')

    case 'moment/locale/sw':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/sw" */ 'moment/locale/sw')

    case 'moment/locale/ta':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/ta" */ 'moment/locale/ta')

    case 'moment/locale/te':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/te" */ 'moment/locale/te')

    case 'moment/locale/tet':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/tet" */ 'moment/locale/tet')

    case 'moment/locale/tg':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/tg" */ 'moment/locale/tg')

    case 'moment/locale/th':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/th" */ 'moment/locale/th')

    case 'moment/locale/tk':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/tk" */ 'moment/locale/tk')

    case 'moment/locale/tl-ph':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/tl-ph" */ 'moment/locale/tl-ph')

    case 'moment/locale/tlh':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/tlh" */ 'moment/locale/tlh')

    case 'moment/locale/tr':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/tr" */ 'moment/locale/tr')

    case 'moment/locale/tzl':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/tzl" */ 'moment/locale/tzl')

    case 'moment/locale/tzm-latn':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/tzm-latn" */ 'moment/locale/tzm-latn')

    case 'moment/locale/tzm':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/tzm" */ 'moment/locale/tzm')

    case 'moment/locale/ug-cn':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/ug-cn" */ 'moment/locale/ug-cn')

    case 'moment/locale/uk':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/uk" */ 'moment/locale/uk')

    case 'moment/locale/ur':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/ur" */ 'moment/locale/ur')

    case 'moment/locale/uz-latn':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/uz-latn" */ 'moment/locale/uz-latn')

    case 'moment/locale/uz':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/uz" */ 'moment/locale/uz')

    case 'moment/locale/vi':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/vi" */ 'moment/locale/vi')

    case 'moment/locale/x-pseudo':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/x-pseudo" */ 'moment/locale/x-pseudo')

    case 'moment/locale/yo':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/yo" */ 'moment/locale/yo')

    case 'moment/locale/zh-hk':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/zh-hk" */ 'moment/locale/zh-hk')

    case 'moment/locale/zh-mo':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/zh-mo" */ 'moment/locale/zh-mo')

    case 'moment/locale/zh-tw':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/zh-tw" */ 'moment/locale/zh-tw')

    case 'moment/locale/ca':
      return import(/* webpackChunkName: "moment/locale/ca" */ './ext/custom_moment_locales/ca')

    case 'moment/locale/de':
      return import(/* webpackChunkName: "moment/locale/de" */ './ext/custom_moment_locales/de')

    case 'moment/locale/fa':
      return import(/* webpackChunkName: "moment/locale/fa" */ './ext/custom_moment_locales/fa')

    case 'moment/locale/fr':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/fr" */ 'moment/locale/fr')

    case 'moment/locale/fr-ca':
      // @ts-expect-error
      return import(/* webpackChunkName: "moment/locale/fr" */ 'moment/locale/fr-ca')

    case 'moment/locale/he':
      return import(/* webpackChunkName: "moment/locale/he" */ './ext/custom_moment_locales/he')

    case 'moment/locale/ht-ht':
      return import(
        /* webpackChunkName: "moment/locale/ht-ht" */ './ext/custom_moment_locales/ht_ht'
      )

    case 'moment/locale/hy-am':
      return import(
        /* webpackChunkName: "moment/locale/hy-am" */ './ext/custom_moment_locales/hy_am'
      )

    case 'moment/locale/mi-nz':
      return import(
        /* webpackChunkName: "moment/locale/mi-nz" */ './ext/custom_moment_locales/mi_nz'
      )

    case 'moment/locale/pl':
      return import(/* webpackChunkName: "moment/locale/pl" */ './ext/custom_moment_locales/pl')

    case 'moment/locale/sl':
      // @ts-expect-erro
      return import(/* webpackChunkName: "moment/locale/sl" */ './ext/custom_moment_locales/sl')

    case 'moment/locale/ja':
      return import(/* webpackChunkName: "moment/locale/ja" */ './ext/custom_moment_locales/ja')

    case 'moment/locale/zh-cn':
      return import(
        /* webpackChunkName: "moment/locale/zh-cn" */ './ext/custom_moment_locales/zh_cn'
      )

    default:
      console.warn("couldn't load moment/locale/", locale)
  }
}
