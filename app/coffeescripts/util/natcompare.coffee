#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define ['i18nObj'], (I18n) ->
  strings: (x, y) ->
    locale = I18n.locale || 'en-US'
    locale_map = {'zh_Hant': 'zh-Hant'}
    locale = locale_map[locale] || locale
    x.localeCompare(y, locale, { sensitivity: 'accent', ignorePunctuation: true, numeric: true})

  by: (f) ->
    return (x, y) =>
      @strings(f(x), f(y))

  byKey: (key) -> @by((x) -> x[key])

  byGet: (key) -> @by((x) -> x.get(key))
