#
# Copyright (C) 2012 Instructure, Inc.
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
#

define [
  'i18n!recipient_input'
  'jquery'
  'underscore'
  'compiled/util/contextList'
  'compiled/widget/TokenInput'
  'str/htmlEscape'
], (I18n, $, _, contextList, TokenInput, h) ->

  class ContextSearch extends TokenInput

    defaults: ->
      placeholder: I18n.t('context_search_placeholder', 'Enter a name, course, or group')
      selector:
        messages: {noResults: I18n.t('no_results', 'No results found')}
        limiter: -> 5
        populator: @populator
        preparer: @preparer
        baseData:
          synthetic_contexts: 1
        browser:
          data:
            per_page: -1
            types: ['context']

    constructor: ($node, options) ->
      options = $.extend true, {}, @defaults(), options
      @prefixUserIds = options.prefixUserIds
      @contexts = options.contexts
      @canToggle = options.canToggle if options.canToggle
      super $node, options

    populator: (selector, $node, data, options={}) =>
      data.id = "#{data.id}"
      data.type ?= 'user'
      
      if data.avatar_url
        $img = $('<img class="avatar" />')
        $img.attr('src', data.avatar_url)
        $node.append($img)
      $b = $('<b />')
      $b.text(data.name)
      $name = $('<span />', class: 'name')
      $contextInfo = @buildContextInfo(data) unless options.parent
      $name.append($b, $contextInfo)
      $span = $('<span />', class: 'details')
      if data.common_courses?
        $span.html(@contextList(courses: data.common_courses, groups: data.common_groups))
      else if data.user_count?
        $span.text(I18n.t('people_count', 'person', {count: data.user_count}))
      else if data.item_count?
        if data.id.match(/_groups$/)
          $span.text(I18n.t('groups_count', 'group', {count: data.item_count}))
        else if data.id.match(/_sections$/)
          $span.text(I18n.t('sections_count', 'section', {count: data.item_count}))
      else if data.subText
        $span.text(data.subText)
      $node.append($name, $span)
      $node.attr('title', data.name)
      text = data.name
      if options.parent
        if data.selectAll and data.noExpand # "Select All", e.g. course_123_all -> "Spanish 101: Everyone"
          text = options.parent.data('text')
        else if data.id.match(/_\d+_/) # e.g. course_123_teachers -> "Spanish 101: Teachers"
          text = I18n.beforeLabel(options.parent.data('text')) + " " + text
      $node.data('text', text)
      $node.data('id', if data.type is 'context' or not @prefixUserIds then data.id else "user_#{data.id}")
      data.rootId = options.ancestors[0]
      $node.data('user_data', data)
      $node.addClass(data.type)
      if options.level > 0 and selector.options.showToggles
        $node.prepend('<a class="toggle"><i></i></a>')
        $node.addClass('toggleable') if @canToggle(data)
      if data.type is 'context' and not data.noExpand
        $node.prepend('<a class="expand"><i></i></a>')
        $node.addClass('expandable')

    canToggle: (data) ->
      not data.item_count # can't toggle certain synthetic contexts, e.g. "Student Groups"

    buildContextInfo: (data) =>
      match = data.id.match(/^(course|section)_(\d+)$/)
      termInfo = @contexts["#{match[1]}s"][match[2]] if match

      contextInfo = data.context_name or ''
      contextInfo = if contextInfo.length < 40 then contextInfo else contextInfo.substr(0, 40) + '...'
      if termInfo?.term
        contextInfo = if contextInfo
          "#{contextInfo} - #{termInfo.term}"
        else
          termInfo.term

      if contextInfo
        $('<span />', class: 'context_info').text("(#{contextInfo})")
      else
        ''

    contextList: (contexts) =>
      contexts = {courses: _.keys(contexts.courses), groups: _.keys(contexts.groups)}
      contextList(contexts, @contexts, linkToContexts: false, hardCutoff: 2)

  $.fn.contextSearch = (options) ->
    @each ->
      new ContextSearch $(this), $.extend(true, {}, options)

  ContextSearch