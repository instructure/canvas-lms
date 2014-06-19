define [ 'ember', 'compiled/behaviors/tooltip' ], (Ember) ->
  {$} = Ember

  # This view takes care of stuffing data inside the .auxiliary blocks inside
  # a tooltip as well as managing the report generation progress bar visuals.
  Ember.View.extend
    classNames: [ 'report-generator', 'inline' ]

    createTooltip: ->
      # the reason we're using a reference to the tooltip content is because
      # tooltip#content() may be called more than once and it will fail on
      # successive calls since the content needs to be detached
      $tooltipContent = this.$('.auxiliary').detach()
      $tooltipContainer = null
      $view = this.$()

      $view.tooltip({
        tooltipClass: 'center bottom vertical'
        show: false
        hide: false
        items: '[title]'
        position:
          my: 'center bottom'
          at: 'center top'
        content: () ->
          $tooltipContent
        create: ->
          $tooltipContainer = $tooltipContent.parent()
        # we need to re-attach the tooltip content element back into the view
        # whenever the tooltip is closed so that Ember doesn't choke when
        # trying to sync the contents (element has to be in the DOM)
        close: (evt, ui) =>
          Ember.run.schedule 'actions', this, ->
            $tooltipContent.appendTo $view
        # and put it back into the tooltip...
        open: =>
          Ember.run.schedule 'actions', this, ->
            $tooltipContent.appendTo $tooltipContainer
      }).data('tooltip')

    createOrUpdateTooltip: (->
      Ember.run.schedule 'afterRender', this, ->
        if @tooltip
          @tooltip.options.content().remove()
          @tooltip.destroy()

        @tooltip = @createTooltip()
        @$progressBar = @tooltip.options.content().find('.bar')
    ).observes('controller.file')

    removeTooltip: (->
      if @tooltip
        @tooltip.destroy()
    ).on('willDestroyElement')

    repositionTooltip: ->
      $tooltipTarget = @$(@tooltip.options.items)
      $tooltip = @tooltip._find($tooltipTarget)

      if $tooltip.length
        $tooltip.position $.extend(@tooltip.options.position, {
          of: $tooltipTarget
        })

    tickProgressBar: (->
      Ember.run.schedule 'afterRender', this, ->
        @repositionTooltip()
        @$progressBar.css {
          width: "#{@get('controller.progress.completion')}%"
        }
    ).observes('controller.progress.completion')