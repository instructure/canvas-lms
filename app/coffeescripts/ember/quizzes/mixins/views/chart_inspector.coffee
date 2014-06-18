define [ 'ember', 'vendor/d3.v3' ], ({Mixin}, d3) ->
  d3.selection.prototype.inspectable = (view) ->
    this
      .on('mouseover', view.inspect.bind(view))
      .on('mouseout', view.stopInspecting.bind(view))

  # This view mixin adds support displaying tooltips for data points in a d3
  # chart.
  Mixin.create({
    # Override this to prepare the set of items that will be used as content to
    # display in the tooltip for each distinct answer.
    #
    # Expected format:
    #
    # [{
    #   "id": "some_unique_answer_id",
    #   "responses": 3,
    #   "ratio": 50,
    #   "text": "Some answer text that will be displayed below the counters."
    # }, { ... }]
    #
    # The "id" field must be present in both these items and your d3 chart's
    # data points because it's the only way we can tell that a certain tooltip
    # content is fit for a given data point.
    #
    # This defaults to whatever the controller's #chartData() method returns.
    answerTooltips: (->
      @get('controller.chartData')
    ).property()

    tooltipOptions:
      # You can tweak these to achieve better positioning of the tip, e.g: pad
      # the tip four pixels to the right: { my: 'center+4 bottom' }
      position:
        my: 'center bottom'
        at: 'center top'

    hideAuxiliaryContent: (->
      @$('.auxiliary').hide()
    ).on('didInsertElement')

    buildInspector: ->
      @inspector = @$('.inspector').tooltip({
        tooltipClass: 'center bottom vertical',
        show: false,
        hide: false
      }).data('tooltip')

    inspect: (datapoint) ->
      content = @$(".auxiliary [data-answer='#{datapoint.id}']")
      target = d3.event.target
      inspector = @inspector || @buildInspector()
      inspector.option
        content: () -> content.clone()
        position:
          my: @get('tooltipOptions.position.my')
          at: @get('tooltipOptions.position.at')
          of: target
          collision: 'fit fit'
      inspector.element.mouseover()

    stopInspecting: ->
      @inspector.element.mouseout()

    removeInspector: (->
      if @inspector
        @inspector.destroy()
        @inspector = null
    ).on('willDestroyElement')
  })