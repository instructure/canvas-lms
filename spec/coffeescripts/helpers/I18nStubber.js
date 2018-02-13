#
# Copyright (C) 2015 - present Instructure, Inc.
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
  frames = []

  I18nStubber =
    pushFrame: ->
      frames.push
        locale: I18n.locale
        translations: I18n.translations
      I18n.locale = null
      I18n.translations = {'en': {}}
      I18n.fallbacksMap = null

    popFrame: ->
      throw 'I18nStubber: pop without a stored frame' unless frames.length
      {locale, translations} = frames.pop()
      I18n.locale = locale
      I18n.translations = translations
      I18n.fallbacksMap = null

    clear: ()->
      while(frames.length > 0)
        this.popFrame()

    stub: (locale, translations, cb) ->
      return @withFrame((=> @stub(locale, translations)), cb) if cb
      throw 'I18nStubber: stub without a stored frame' unless frames.length

      I18n.fallbacksMap = null

      # don't merge into a given locale, just replace everything wholesale
      if typeof locale is 'object'
        I18n.translations = locale
        return

      scope = I18n.translations
      scope[locale] = {} unless scope[locale]
      locale = scope[locale]
      for key, value of translations
        scope = locale
        parts = key.split('.')
        last = parts.pop()
        for part in parts
          scope[part] = {} unless scope[part]
          scope = scope[part]
        scope[last] = value

    setLocale: (locale, cb) ->
      throw 'I18nStubber: setLocale without a stored frame' unless frames.length
      I18n.locale = locale

    withFrame: (cbs...) ->
      @pushFrame()
      cb() for cb in cbs
      @popFrame()
