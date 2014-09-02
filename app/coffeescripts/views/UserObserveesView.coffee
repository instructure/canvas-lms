define [
  'underscore'
  'i18n!observees'
  'jst/UserObservees'
  'compiled/views/UserObserveeView'
  'compiled/views/PaginatedCollectionView'
], (_, I18n, template, itemView, PaginatedCollectionView) ->

  class UserObserveesView extends PaginatedCollectionView
    autoFetch: true
    template: template
    itemView: itemView
    className: 'user-observees'

    events:
      'submit .add-observee-form': 'addObservee'

    els: _.extend {}, PaginatedCollectionView::els,
      '.add-observee-form': '$form'

    initialize: ->
      super
      @collection.on 'beforeFetch', =>
        @setLoading(true)
      @collection.on 'fetch', =>
        @setLoading(false)

    addObservee: (ev) ->
      ev.preventDefault()

      observee = @$form.getFormData()
      d = $.post(@collection.url(), {observee: observee})

      d.done (model) =>
        @collection.add([model], merge: true)
        $.flashMessage(I18n.t('observee_added', 'Now observing %{user}', user: model.name))

        @$form.get(0).reset()
        @focusForm()

      d.error (response) =>
        @$form.formErrors(JSON.parse(response.responseText))

        @focusForm()

    focusForm: ->
      field = @$form.find(":input[value='']:not(button)").first()
      field = @$form.find(":input:not(button)") unless field.length
      field.focus()

    setLoading: (loading) ->
      @$el.toggleClass('loading', loading)
      @$('.observees-list-container').attr('aria-busy', if loading then 'true' else 'false')
