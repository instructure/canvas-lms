define [
  'Backbone'
  'jquery'
  'i18n!context_modules'
  'jquery.loadingImg'
], (Backbone, $, I18n) -> 
  class ContextModules extends Backbone.View
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

