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
  'compiled/widget/TokenInput'
  'str/htmlEscape'
], (I18n, $, TokenInput, h) ->

  class ContextSearch extends TokenInput

    defaults: ->
      placeholder: I18n.t('context_search_placeholder', 'Enter a name, course, or group')
      selector:
        messages: {noResults: I18n.t('no_results', 'No results found')}
        limiter: (o) => 5
        populator: @populator()
        preparer: @preparer
        baseData:
          synthetic_contexts: 1
        browser:
          data:
            per_page: -1
            type: 'context'

    constructor: ($node, options) ->
      options = $.extend true, {}, @defaults(), options
      @contexts = options.contexts
      super $node, options

    populator: (pOptions={}) =>
      (selector, $node, data, options={}) =>
        data.id = "#{data.id}"
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
          $span.text(@contextList(courses: data.common_courses, groups: data.common_groups))
        else if data.type and data.user_count?
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
        $node.data('id', if data.type is 'context' or not pOptions.prefixUserIds then data.id else "user_#{data.id}")
        data.rootId = options.ancestors[0]
        $node.data('user_data', data)
        $node.addClass(if data.type then data.type else 'user')
        if options.level > 0 and selector.options.showToggles
          $node.prepend('<a class="toggle"><i></i></a>')
          $node.addClass('toggleable') unless data.item_count # can't toggle certain synthetic contexts, e.g. "Student Groups"
        if data.type == 'context' and not data.noExpand
          $node.prepend('<a class="expand"><i></i></a>')
          $node.addClass('expandable')

    preparer: (postData, data, parent) =>
      context = postData.context
      if not postData.search and context and data.length > 1
        if context.match(/^(course|section)_\d+$/)
          # i.e. we are listing synthetic contexts under a course or section
          data.unshift
            id: "#{context}_all"
            name: I18n.t('enrollments_everyone', 'Everyone')
            user_count: parent.data('user_data').user_count
            type: 'context'
            avatar_url: parent.data('user_data').avatar_url
            selectAll: true
        else if context.match(/^((course|section)_\d+_.*|group_\d+)$/) and not context.match(/^course_\d+_(groups|sections)$/)
          # i.e. we are listing all users in a group or synthetic context
          data.unshift
            id: context
            name: I18n.t('select_all', 'Select All')
            user_count: parent.data('user_data').user_count
            type: 'context'
            avatar_url: parent.data('user_data').avatar_url
            selectAll: true
            noExpand: true # just a magic select-all checkbox, you can't drill into it

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

    contextList: (contexts, withUrl=false, limit=2) =>
      compare = (contextA, contextB) ->
        strA = contextA.name.toLowerCase()
        strB = contextB.name.toLowerCase()
        if strA < strB then -1 else if strA > strB then 1 else 0

      formatContext = (context) ->
        if withUrl and context.type is "course"
          return "<span class='context' data-url='#{h(context.url)}'>#{h(context.name)}</span>"
        else
          return h(context.name)

      sharedContexts = (course for id, roles of contexts.courses when course = @contexts.courses[id]).
                 concat(group for id, roles of contexts.groups when group = @contexts.groups[id]).
                 sort(compare)[0...limit]

      $.toSentence(formatContext(context) for context in sharedContexts)

  $.fn.contextSearch = (options) ->
    @each ->
      new ContextSearch $(this), $.extend(true, {}, options)

  ContextSearch