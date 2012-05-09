define [
  'jquery'
  'underscore'
  'jst/calendar/contextSelector'
  'jst/calendar/contextSelectorItem'
  'compiled/fn/preventDefault'
], ($, _, contextSelectorTemplate, contextSelectorItemTemplate, preventDefault) ->

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

    toggleSections: (jsEvent) =>
      $(jsEvent.target).toggleClass('ag-sections-expanded')
      @$sectionsList.toggleClass('hidden')

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

    disable: ->
      @$contentCheckbox.prop('disabled', true)
      @disableSections()

    disableSections: ->
      @$sectionCheckboxes.prop('disabled', true)

    lock: ->
      @locked = true
      @disable()
      @disableSections()

    isChecked: -> @state != 'off'

    sections: ->
      checked = @$sectionCheckboxes.filter(':checked')
      if checked.length == @$sectionCheckboxes.length
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

      for contextCode in @apptGroup.context_codes when @contextSelectorItems[contextCode]
        @contextSelectorItems[contextCode].setState('on')
        @contextSelectorItems[contextCode].lock()

      if @apptGroup.sub_context_codes.length > 0
        if @apptGroup.sub_context_codes[0].match /^group_category_/
          for c, item of @contextSelectorItems
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
