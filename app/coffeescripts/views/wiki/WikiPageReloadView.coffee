define [
  'underscore'
  'Backbone'
], (_, Backbone) ->

  pageReloadOptions = ['reloadMessage', 'warning']

  class WikiPageReloadView extends Backbone.View
    setViewProperties: false
    template: -> "<div class='alert alert-#{$.raw if @options.warning then 'warning' else 'info'} reload-changed-page'>#{$.raw @reloadMessage}</div>"

    defaults:
      modelAttributes: ['title', 'url', 'body']
      warning: false

    events:
      'click a.reload': 'reload'

    initialize: (options) ->
      super
      _.extend(this, _.pick(options || {}, pageReloadOptions))

    pollForChanges: ->
      return unless @model

      view = @
      model = @model
      latestRevision = @latestRevision = model.latestRevision()
      if latestRevision && !model.isNew()
        latestRevision.on 'change:revision_id', ->
          # when the revision changes, query the full record
          latestRevision.fetch(data: {summary: false}).done ->
            view.render()
            view.trigger('changed')

        latestRevision.pollForChanges()

    stopPolling: ->
      @latestRevision?.stopPolling()

    reload: (ev) ->
      ev?.preventDefault()
      @model.set(_.pick(@latestRevision.attributes, @options.modelAttributes))
      @trigger('reload')
