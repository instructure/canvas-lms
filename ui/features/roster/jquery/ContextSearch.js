//
// Copyright (C) 2012 - present Instructure, Inc.
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
//

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {keys} from 'lodash'
import contextList from '../util/contextList'
import _TokenInput from './TokenInput'
import avatarTemplate from '@canvas/avatar/jst/_avatar.handlebars'
import _inherits from '@babel/runtime/helpers/esm/inheritsLoose'
import newless from 'newless'

const I18n = useI18nScope('recipient_input')

const TokenInput = newless(_TokenInput)

_inherits(ContextSearch, TokenInput)

export default function ContextSearch($node, options) {
  this.populator = this.populator.bind(this)
  this.buildContextInfo = this.buildContextInfo.bind(this)
  this.contextList = this.contextList.bind(this)
  options = $.extend(true, {}, this.defaults(), options)
  this.prefixUserIds = options.prefixUserIds
  this.contexts = options.contexts
  if (options.canToggle) {
    this.canToggle = options.canToggle
  }
  return TokenInput.call(this, $node, options)
}

Object.assign(ContextSearch.prototype, {
  defaults() {
    return {
      placeholder: I18n.t('context_search_placeholder', 'Enter a name, course, or group'),
      title: I18n.t('context_search_title', 'Name, course, or group'),
      selector: {
        messages: {noResults: I18n.t('no_results', 'No results found')},
        populator: this.populator,
        baseData: {
          synthetic_contexts: 1,
        },
        browser: {
          data: {
            types: ['context'],
          },
        },
      },
    }
  },

  populator(selector, $node, data, options = {}) {
    let $contextInfo
    const noExpand = options.noExpand != null ? options.noExpand : data.noExpand

    data.id = `${data.id}`
    if (data.type == null) {
      data.type = 'user'
    }

    if (data.avatar_url) {
      if (data.type === 'user') {
        $node.append(avatarTemplate(data))
      } else {
        $node.append($('<div class="avatar-box" />'))
      }
    }

    const $b = $('<b />')
    $b.text(data.name)
    const $description = $('<span />', {id: `${data.type}-${data.id}-description`})
    const $name = $('<span />', {class: 'name'})
    if (!options.parent) {
      $contextInfo = this.buildContextInfo(data)
    }
    $name.append($b, $contextInfo)
    const $span = $('<span />', {class: 'details'})
    if (data.common_courses != null) {
      const contextListHtml = this.contextList({
        courses: data.common_courses,
        groups: data.common_groups,
      })
      $span.html(contextListHtml)
    } else if (data.user_count != null) {
      $span.text(I18n.t('people_count', 'person', {count: data.user_count}))
    } else if (data.item_count != null) {
      if (data.id.match(/_groups$/)) {
        $span.text(I18n.t('groups_count', 'group', {count: data.item_count}))
      } else if (data.id.match(/_sections$/)) {
        $span.text(I18n.t('sections_count', 'section', {count: data.item_count}))
      }
    } else if (data.subText) {
      $span.text(data.subText)
    }
    $description.append($name, $span)
    $node.append($description)
    $node.attr('role', 'menuitem')
    $node.attr('aria-labelledby', `${data.type}-${data.id}-description`)
    let text = data.name
    if (options.parent) {
      if (data.selectAll && noExpand) {
        // "Select All", e.g. course_123_all -> "Spanish 101: Everyone"
        text = options.parent.data('text')
      } else if (data.id.match(/_\d+_/)) {
        // e.g. course_123_teachers -> "Spanish 101: Teachers"
        text = I18n.beforeLabel(options.parent.data('text')) + ' ' + text
      }
    }
    $node.data('text', text)
    $node.data('id', data.type === 'context' || !this.prefixUserIds ? data.id : `user_${data.id}`)
    data.rootId = options.ancestors[0]
    $node.data('user_data', data)
    $node.addClass(data.type)
    if (options.level > 0 && selector.options.showToggles) {
      $node.prepend('<a class="toggle"><i></i></a>')
      if (this.canToggle(data)) {
        $node.addClass('toggleable')
      }
    }
    if (data.type === 'context' && !noExpand) {
      $node.prepend('<a class="expand"><i></i></a>')
      return $node.addClass('expandable')
    }
  },

  canToggle(data) {
    return !data.item_count // can't toggle certain synthetic contexts, e.g. "Student Groups"
  },

  buildContextInfo(data) {
    let termInfo
    const match = data.id.match(/^(course|section)_(\d+)$/)
    if (match) {
      termInfo = this.contexts[`${match[1]}s`][match[2]]
    }

    let contextInfo = data.context_name || ''
    contextInfo = contextInfo.length < 40 ? contextInfo : contextInfo.substr(0, 40) + '...'
    if (termInfo != null ? termInfo.term : undefined) {
      contextInfo = contextInfo ? `${contextInfo} - ${termInfo.term}` : termInfo.term
    }

    if (contextInfo) {
      return $('<span />', {class: 'context_info'}).text(`(${contextInfo})`)
    } else {
      return ''
    }
  },

  contextList(contexts) {
    contexts = {courses: keys(contexts.courses), groups: keys(contexts.groups)}
    return contextList(contexts, this.contexts, {linkToContexts: false, hardCutoff: 2})
  },
})

$.fn.contextSearch = function (options) {
  return this.each(function () {
    return new ContextSearch($(this), $.extend(true, {}, options))
  })
}
