define [
  'Backbone'
  'jquery'
  'i18n!context_modules'
  'jquery.loadingImg'
], (Backbone, $, I18n) ->
  ###
  xsslint jqueryObject.identifier dragItem dragModule
  ###

  class ContextModules extends Backbone.View
    @optionProperty 'modules'

    #events:
    #  'click .change-workflow-state-link' : 'toggleWorkflowState'

    # Method Summary
    #   Toggles a module from "Published" to "Unpublished". This workes by 
    #   changing a modules workflow_state. A workflow state can be either
    #   "unpublished" or "active" (which means published). This uses the 
    #   div with .context_module class to store the workflow-state and 
    #   extract the url the request should be set to. 
    #
    # @api private
    toggleWorkflowState: (event) => 
      event.preventDefault()
      @$context_module = $(event.target).parents('.context_module')
      # Get the data attributes for this module out of the dom (to be used
      # to submit a PUT request) 
      module_url = @$context_module.data('module-url')
      @workflow_state = @$context_module.data('workflow-state')

      # Set up the request options
      request_options = 
        url: module_url
        type: 'PUT'
        beforeSend: => 
          @$context_module.loadingImage()
        success: @success
        error: @error
      @setRequestPublishOptions(request_options)
      $.ajax request_options # make the request

    # Method Summary
    #   If a successful request has been made, we want to store the workflow state
    #   back into the context modules div and add approprate styling for a published
    #   or unpublished module. 
    # @api private
    success: (response) =>
      @$context_module.data 'workflow-state', response.context_module.workflow_state
      if response.context_module.workflow_state == 'unpublished'
        @addUnpublishAttributes()
      else
        @addPublishAttributes()
      @$context_module.loadingImage('remove')

    # Method Summary
    #   We don't need to do anything except remove the loading icon and show an alert
    #   if there was an error.
    # @api private
    error: (response) => 
      alert 'This module could not be published'
      @$context_module.loadingImage('remove')

    # Method Summary
    #   In order to set the workflow_state of a module, you must send over the params
    #   either unpublish=1 or publish=1 You don't want to send both options at the 
    #   same time. We are always sending inverse of what the current module is ie: if 
    #   its unpublished we send a request to publish it. Remember, active means published.
    # @api private
    setRequestPublishOptions:(request_options) -> 
      # The new workflow state is actually going to send published = 1 or unpublished = 1 to the server.
      # If it's currently 'active' then we want the next value to be unpublished. 
      if @workflow_state is 'active'
        request_options.data = "unpublish=1"
      else
        request_options.data = "publish=1"

    # Method Summary
    #   We need to add both icons, text and css classes to elements that are unpublished
    # @api private
    addUnpublishAttributes: -> 
      @$context_module.find('.workflow-state-action')
                      .text I18n.t("context_modules.publish", "Publish")

      @$context_module.find('.workflow-state-icon')
                      .addClass('publish-module-link')
                      .removeClass('unpublish-module-link')

      @$context_module.find('.draft-text').removeClass('hide')
            
      @$context_module.addClass 'unpublished_module'

    # Method Summary
    #   We need to add both icons, text and css classes to elements that are published
    # @api private
    addPublishAttributes: -> 
      @$context_module.find('.workflow-state-action')
                      .text I18n.t("context_module.unpublish", "Unpublish")

      @$context_module.find('.workflow-state-icon')
                      .addClass('unpublish-module-link')
                      .removeClass('publish-module-link')

      @$context_module.find('.draft-text').addClass('hide')

      @$context_module.removeClass 'unpublished_module'

    # Drag-And-Drop Accessibility:
    keyCodes:
      32: 'Space'
      38: 'UpArrow'
      40: 'DownArrow'

    moduleSelector: "div.context_module"
    itemSelector: "table.context_module_item"

    initialize: ->
      super
      @$contextModules = $("#context_modules")
      @$contextModules.parent().on 'keydown', @onKeyDown

    onKeyDown: (e) =>
      $target = $(e.target)
      fn      = "on#{@keyCodes[e.keyCode]}Key"
      if @[fn]
        e.preventDefault()
        @[fn].call(this, e, $target)

    getFocusedElement: (el) ->
      parent = el.parents(@itemSelector).first()
      el = parent unless @empty(parent)

      unless el.is(@itemSelector)
        parent = el.parents(@moduleSelector).first()
        el = parent unless @empty(parent)

        unless el.is(@moduleSelector)
          el = @$contextModules

      el

    # Internal: move to the previous element
    # returns nothing
    onUpArrowKey: (e, $target) ->
      el = @getFocusedElement($target)

      if el.is(@itemSelector)
        prev = el.prev(@itemSelector)
        if @empty(prev) || @$contextModules.data('dragModule')
          prev = el.parents(@moduleSelector).first()

      else if el.is(@moduleSelector)
        if @$contextModules.data('dragItem')
          prev = @$contextModules.data('dragItemModule')
        else
          prev = el.prev(@moduleSelector)
          if @empty(prev)
            prev = @$contextModules
          else if !@$contextModules.data('dragModule')
            lastChild = prev.find(@itemSelector).last()
            prev = lastChild unless @empty(lastChild)

      prev.focus() if prev && !@empty(prev)

    # Internal: move to the next element
    # returns nothing
    onDownArrowKey: (e, $target) ->
      el = @getFocusedElement($target)

      if el.is(@itemSelector)
        next = el.next(@itemSelector)
        if @empty(next) && !@$contextModules.data('dragItem')
          parent = el.parents(@moduleSelector).first()
          next = parent.next(@moduleSelector)

      else if el.is(@moduleSelector)
        next = el.find(@itemSelector).first()
        if @empty(next) || @$contextModules.data('dragModule')
          next = el.next(@moduleSelector)

      else
        next = @$contextModules.find(@moduleSelector).first()

      next.focus() if next && !@empty(next)

    # Internal: mark the current element to begin dragging
    # or drop the current element
    # returns nothing
    onSpaceKey: (e, $target) ->
      el = @getFocusedElement($target)
      if dragItem = @$contextModules.data('dragItem')
        unless el.is(dragItem)
          parentModule = @$contextModules.data('dragItemModule')
          if el.is(@itemSelector) && !@empty(el.parents(parentModule)) # i.e. it's an item in the same module
            el.after(dragItem)
          else
            parentModule.find('.items').prepend(dragItem)
          modules.updateModuleItemPositions(null, item: dragItem.parent())

        dragItem.attr('aria-grabbed', false)
        @$contextModules.data('dragItem', null)
        @$contextModules.data('dragItemModule', null)
        dragItem.focus()
      else if dragModule = @$contextModules.data('dragModule')
        if el.is(@itemSelector)
          el = el.parents(@moduleSelector).first()

        if !el.is(dragModule)
          if @empty(el) || el.is(@$contextModules)
            @$contextModules.prepend(dragModule)
          else
            el.after(dragModule)
          modules.updateModulePositions()

        dragModule.attr('aria-grabbed', false)
        @$contextModules.data('dragModule', null)
        dragModule.focus()
      else if !el.is(@$contextModules)
        el.attr('aria-grabbed', true)
        if el.is(@itemSelector)
          @$contextModules.data('dragItem', el)
          @$contextModules.data('dragItemModule', el.parents(@moduleSelector).first())
        else if el.is(@moduleSelector)
          @$contextModules.data('dragModule', el)
        el.blur()
        el.focus()

    # Internal: returns whether the selector is empty
    empty: (selector) ->
      selector.length == 0
