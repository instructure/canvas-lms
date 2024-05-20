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

import {chain, values, pick, includes, clone} from 'lodash'
import h, {raw} from '@instructure/html-escape'
import listWithOthers from './listWithOthers'
import '@canvas/jquery/jquery.instructure_misc_helpers'

function prepare(context, filters) {
  context = clone(context)
  context.activeFilter = includes(filters, `${context.type}_${context.id}`)
  context.sortBy = `${context.activeFilter ? 0 : 1}_${context.name.toLowerCase()}`
  return context
}

function format(context, linkToContexts) {
  let html = h(context.name)
  if (context.activeFilter) {
    html = `<span class='active-filter'>${html}</span>`
  }
  if (linkToContexts && context.type === 'course') {
    html = `<a href='${h(context.url)}'>${html}</a>`
  }
  return raw(html)
}

// given a map of ids by type (e.g. {courses: [1, 2], groups: ...})
// and a map of possible contexts by type,
// return an html sentence/list of the contexts (maybe links, etc., see
// options)
export default function contextList(contextMap, allContexts, options = {}) {
  const filters = options.filters != null ? options.filters : []
  let contexts = []
  for (const type in contextMap) {
    const ids = contextMap[type]
    contexts = contexts.concat(values(pick(allContexts[type], ids)))
  }
  contexts = chain(contexts)
    .map(context => prepare(context, filters))
    .sortBy('sortBy')
    .map(context => format(context, options.linkToContexts))
    .value()
  if (options.hardCutoff) contexts = contexts.slice(0, options.hardCutoff)
  return listWithOthers(contexts)
}
