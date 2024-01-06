//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import Ember from 'ember'
import I18n from '@canvas/i18n'
import htmlEscape from '@instructure/html-escape'

Ember.Handlebars.registerHelper('t', (...args1) => {
  const adjustedLength = Math.max(args1.length, 1),
    args = args1.slice(0, adjustedLength - 1),
    hbsOptions = args1[adjustedLength - 1]
  const {hash, hashTypes, hashContexts} = hbsOptions
  const options = {}
  for (const key of Object.keys(hash || {})) {
    const value = hash[key]
    const type = hashTypes[key]
    if (type === 'ID') {
      options[key] = Ember.get(hashContexts[key], value)
    } else {
      options[key] = value
    }
  }

  const wrappers = []
  let key
  while ((key = `w${wrappers.length}`) && options[key]) {
    wrappers.push(options[key])
    delete options[key]
  }
  if (wrappers.length) {
    options.wrapper = wrappers
  }
  return new Ember.Handlebars.SafeString(htmlEscape(I18n.t(...Array.from(args), options)))
})

Ember.Handlebars.registerHelper('__i18nliner_escape', htmlEscape)

Ember.Handlebars.registerHelper('__i18nliner_safe', val => new htmlEscape.SafeString(val))

export default Ember.Handlebars.registerHelper('__i18nliner_concat', (...args1) => {
  const adjustedLength = Math.max(args1.length, 1),
    args = args1.slice(0, adjustedLength - 1)
  return args.join('')
})
