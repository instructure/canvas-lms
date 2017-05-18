#
# Copyright (C) 2012 - present Instructure, Inc.
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

define [
  'jquery'
  'underscore'
  'i18n!context_sector'
  'jst/calendar/contextSelector'
  'jst/calendar/contextSelectorItem'
  'compiled/fn/preventDefault'
], ($, _, I18n, contextSelectorTemplate, contextSelectorItemTemplate, preventDefault) ->

  class ContextSelectorItem
    constructor: (@context) ->
      @state  = 'off'
      @locked = false

    render: ($list) ->
      @$listItem = $(contextSelectorItemTemplate(@context))
      @$listItem.appendTo($list)
      @$sectionsList = @$listItem.find('.ag_sections')

      @$listItem.find('.ag_sections_toggle').click preventDefault @toggleSections
      @$contentCheckbox = @$listItem.find('[name="context_codes[]"]')
      @$contentCheckbox.change preventDefault @change
      @$sectionCheckboxes = @$listItem.find('[name="sections[]"]')
      @$sectionCheckboxes.change @sectionChange

    toggleSections: (e) =>
      @$sectionsList.toggleClass('hidden')
      $toggle = @$listItem.find('.ag_sections_toggle')
      $toggle.toggleClass('ag-sections-expanded')

      if $toggle.hasClass('ag-sections-expanded')
        $toggle.find('.screenreader-only').text(I18n.t('Hide course sections for course %{name}', { name: @context.name }))
      else
        $toggle.find('.screenreader-only').text(I18n.t('Show course sections for course %{name}', { name: @context.name }))

    change: =>
      newState =  switch @state
                    when 'off' then 'on'
                    when 'on' then 'off'
                    when 'partial' then 'on'
      @setState(newState)

    setState: (state) =>
      return if @locked

      @state = state
      switch @state
        when 'on', 'off'
          checked = @state == 'on'
          @$contentCheckbox.prop('checked', checked)
          @$contentCheckbox.prop('indeterminate', false)
          @$sectionCheckboxes.prop('checked', checked)
        when 'partial'
          @$contentCheckbox.prop('checked', true)
          @$contentCheckbox.prop('indeterminate', true)

      $.publish('/contextSelector/changed')

    sectionChange: =>
      switch @$sectionCheckboxes.filter(':checked').length
        when 0
          @setState('off')
        when @$sectionCheckboxes.length
          @setState('on')
        else
          @setState('partial')

    disableSelf: ->
      @$contentCheckbox.prop('disabled', true)

    disableSections: ->
      @$sectionCheckboxes.prop('disabled', true)

    disableAll: ->
      @disableSelf()
      @disableSections()

    lock: ->
      @locked = true
      @disableAll()

    isChecked: -> @state != 'off'

    sections: ->
      checked = @$sectionCheckboxes.filter(':checked')
      if checked.length == @$sectionCheckboxes.length && !@$contentCheckbox.attr('disabled')
        []
      else
        _.map(checked, (cb) -> cb.value)

  class ContextSelector
    constructor: (selector, @apptGroup, @contexts, contextsChangedCB, closeCB) ->
      @$menu = $(selector).html contextSelectorTemplate()

      $contextsList = @$menu.find('.ag-contexts')

      $.subscribe('/contextSelector/changed', => contextsChangedCB @selectedContexts(), @selectedSections())

      @contextSelectorItems = {}
      for c in @contexts
        item = new ContextSelectorItem(c)
        item.render($contextsList)
        @contextSelectorItems[item.context.asset_string] = item

      # if groups can sign up, then we only have one context (course) and one sub-context (group)
      # a context without sub-contexts means the whole context is selected
      # a context with sub-contexts means that under that context, only those sub-contexts are selected
      # there can be a mix of contexts with and without sub-contexts
      if @apptGroup.sub_context_codes.length > 0 and @apptGroup.sub_context_codes[0].match /^group_category_/
        for c, item of @contextSelectorItems
          if c == @apptGroup.context_codes[0]
            item.setState('on')
          item.lock()
      else
        contextsBySubContext = {}

        for c in @contexts
          for section in c.course_sections
            contextsBySubContext[section.asset_string] = c.asset_string

        for subContextCode in @apptGroup.sub_context_codes
          $("[value='#{subContextCode}']").prop('checked', true)
          context = contextsBySubContext[subContextCode]
          item = @contextSelectorItems[context]
          item.sectionChange()
          item.lock()

        for contextCode in @apptGroup.context_codes
          item = @contextSelectorItems[contextCode]
          if item.state == 'off'
            item.setState('on')
            item.lock()

        for c, item of @contextSelectorItems
          unless item.locked || item.context.can_create_appointment_groups.all_sections
            item.toggleSections()
            item.disableSelf()

      $('.ag_contexts_done').click preventDefault closeCB

      contextsChangedCB(@selectedContexts(), @selectedSections())

    selectedContexts: ->
      contexts = _.chain(@contextSelectorItems)
                  .values()
                  .filter( (c) -> c.state != 'off')
                  .map(    (c) -> c.context.asset_string)
                  .value()

      contexts

    selectedSections: ->
      sections = _.chain(@contextSelectorItems)
                  .values()
                  .map(   (c)  -> c.sections())
                  .reject((ss) -> ss.length == 0)
                  .flatten()
                  .value()

      sections
