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
      @sectionsLocked = false

      pubsubHelper = (fn) =>
        (sender) =>
          return if sender is this
          fn.apply(this)

      $.subscribe '/contextSelector/disable', pubsubHelper(@disable)
      $.subscribe '/contextSelector/enable', pubsubHelper(@enable)
      $.subscribe '/contextSelector/uncheck', pubsubHelper(=> @setState('off'))

      $.subscribe '/contextSelector/lockSections', @lockSections

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
          $.publish("/contextSelector/enable", [this])
        when 'partial'
          @$contentCheckbox.prop('checked', true)
          @$contentCheckbox.prop('indeterminate', true)
          $.publish('/contextSelector/disable', [this])
          $.publish('/contextSelector/uncheck', [this])

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

    enable: ->
      unless @locked
        @$contentCheckbox.prop('disabled', false)
        @enableSections()

    enableSections: ->
      unless @lockedSections
        @$sectionCheckboxes.prop('disabled', false)

    lock: ->
      @locked = true
      @disable()
      $.publish('/contextSelector/lockSections')

    lockSections: =>
      @lockedSections = true
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

      if @apptGroup.sub_context_codes.length > 0
        # if you choose sub_contexts when creating an appointment
        # group, the appointment group is locked down
        # TODO: be smarter about this
        for subContextCode in @apptGroup.sub_context_codes
          $("[value='#{subContextCode}']").prop('checked', true)
          for c, item of @contextSelectorItems
            item.sectionChange()
            item.lock()
      else
        for contextCode in @apptGroup.context_codes
          @contextSelectorItems[contextCode].setState('on')
          @contextSelectorItems[contextCode].lock()

      $('.ag_contexts_done').click preventDefault closeCB

      contextsChangedCB(@selectedContexts(), @selectedSections())

    selectedContexts: ->
      contexts = _.chain(@contextSelectorItems)
                  .values()
                  .filter( (c) -> c.state != 'off')
                  .map(    (c) -> c.context.asset_string)
                  .value()

      numPartials = _.filter(contexts, (c) -> c.state == 'partial')
      if numPartials > 1 or numPartials == 1 and contexts.length > 1
        throw "invalid state"

      contexts

    selectedSections: ->
      sections = _.chain(@contextSelectorItems)
                  .values()
                  .map(   (c)  -> c.sections())
                  .reject((ss) -> ss.length == 0)
                  .value()

      throw "invalid state" if sections.length > 1
      sections[0]
