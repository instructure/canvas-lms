#
# Copyright (C) 2013 - present Instructure, Inc.
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

define ['ember', 'i18nObj', 'str/htmlEscape'], (Ember, I18n, htmlEscape) ->
  Ember.Handlebars.registerHelper 't', (args..., hbsOptions) ->
    {hash, hashTypes, hashContexts} = hbsOptions
    options = {}
    for own key, value of hash
      type = hashTypes[key]
      if type is 'ID'
        options[key] = Ember.get(hashContexts[key], value)
      else
        options[key] = value

    wrappers = []
    while (key = "w#{wrappers.length}") and options[key]
      wrappers.push(options[key])
      delete options[key]
    options.wrapper = wrappers if wrappers.length
    new Ember.Handlebars.SafeString htmlEscape I18n.t(args..., options)

  Ember.Handlebars.registerHelper '__i18nliner_escape', htmlEscape

  Ember.Handlebars.registerHelper '__i18nliner_safe', (val) ->
    new htmlEscape.SafeString(val)

  Ember.Handlebars.registerHelper '__i18nliner_concat', (args..., options) ->
    args.join("")
