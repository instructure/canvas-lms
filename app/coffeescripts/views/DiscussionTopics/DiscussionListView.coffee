define [
  'compiled/views/CollectionView'
  'jst/DiscussionTopics/discussionList'
  'compiled/views/DiscussionTopics/DiscussionView'
], (CollectionView, template, itemView) ->

  class DiscussionListView extends CollectionView
    template: template

    itemView: itemView

    showSpinner: true

    showMessage: false

    spinnerOpts:
      color: '#333'
      length: 5
      radius: 6
      width: 2

    events:
      'click .al-trigger': 'onAdminClick'

    @optionProperty 'title'
    @optionProperty 'listId'

    attachCollection: ->
      @collection.on('change:hidden', @onChange)
      @collection.on('fetched:last',  @onFetchLast)
      super

    onAdminClick: (e) ->
      e.preventDefault()

    startLoader: ->
      target  = @$el.find('.loader')
      spinner = new Spinner(@spinnerOpts)
      spinner.spin(target[0])

    render: ->
      super
      @onChange()
      @startLoader() if @showSpinner

    onChange: =>
      @$el.find('.no-content').toggle(@empty()) if @showMessage

    onFetchLast: =>
      @$el.find('.loader').remove()
      @showSpinner = false
      @showMessage = true
      @onChange()

    empty: ->
      @collection.isEmpty() or @collection.all((m) -> m.get('hidden'))

    toJSON: ->
      @options
