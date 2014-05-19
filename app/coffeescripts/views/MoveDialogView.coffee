define [
  'jquery'
  'underscore'
  'compiled/views/DialogFormView'
  'compiled/views/MoveDialogSelect'
  'jst/MoveDialog'
  'jst/EmptyDialogFormWrapper'
], ($, _, DialogFormView, MoveDialogSelect, template, wrapper) ->

  class MoveDialogView extends DialogFormView
    setViewProperties: false

    className: 'form-dialog'

    defaults:
      width: 450
      height: 340

    # {bool}
    @optionProperty 'nested'

    # {Backbone.Collection}
    # Backbone Collection whose models contain a reference
    # to another Backbone Collection - referenced by @childKey
    # required if @nested
    @optionProperty 'parentCollection'

    # {string}
    # text used to describe the select
    # MUST BE I18N STRING
    # required if @nested
    @optionProperty 'parentLabelText'

    # {string}
    # The name of the attribute on @model
    # that stores the relation to @parentCollection
    @optionProperty 'parentKey'

    # {string}
    # key to use to get the child collection from a model
    # in the parent collection
    # so if assignments are stored on a model and you
    # access the collection like so:
    # `model.get('assignments')`
    # then the childKey would be 'assignments'
    # required if @nested
    @optionProperty 'childKey'

    # {jQuery selector}
    # link to focus on after dialog is closed
    # without taking any action
    @optionProperty 'closeTarget'

    # {string or function}
    # url to post to when saving the form
    #
    # if a function, will be called with this
    # view as context
    @optionProperty 'saveURL'

    events: _.extend({}, @::events,
      'click .dialog_closer': 'close'
      'change .move_select_parent_collection': 'updateListView'
    )

    els:
      '.child_container': '$childContainer'
      '.form-dialog-content': '$content'

    template: template
    wrapperTemplate: wrapper

    openAgain: ->
      super
      @initChildViews()
      @dialog.option "close", @cleanup

    # creates @listView and @parentListView (if @nested)
    initChildViews: ->
      @listView = @parentListView = null
      if @nested and @parentCollection
        @listView = new MoveDialogSelect
          model: @model
          excludeModel: true
          lastList: true
        @parentListView = new MoveDialogSelect
          collection: @parentCollection
          model: @model
          labelText: @parentLabelText
      else
        @listView = new MoveDialogSelect
          model: @model
          excludeModel: true
          lastList: true

      @attachChildViews()


    # attaches child views to @$childContainer
    attachChildViews: ->
      container = @$childContainer.detach()
      if @parentListView
        container.append(@parentListView.render().el)
      container.append(@listView.render().el)
      @$content.append(container)

    cleanup: =>
      @parentListView?.remove()
      @listView?.remove()
      @parentListView = @listView = null
      @dialog.option "close", null
      @closeTarget?.focus()

    #lookup new collection, and set it on
    #the nested view
    updateListView: (e)->
      return unless @nested
      groupId = $(e.currentTarget).val()
      group = @parentCollection.get(groupId)
      children = group.get(@childKey)

      @listView.setCollection(children)

    toJSON: ->
      data = @model.toView?() or super

    # should return an array of ids
    # in the order they should save
    getFormData: ->
      $select = @listView.$('select')
      selected = $select.val()
      vals = []
      _.each $select.find('option'), (ele, i) ->
        {value} = ele
        vals.push value unless value == 'last'

      if selected == 'last'
      # just push model onto the end
        vals.push @model.id
      else
      # or find the index to insert it at and splice it in
        vals.splice _.indexOf(vals, selected), 0, @model.id
      vals


    # will always have data as we're
    # overriding getFormData
    #
    # getFromData should return a list
    # of ids
    saveFormData: (data) ->
      url = if typeof @saveURL is 'function'
        @saveURL.call @
      else
        @saveURL
      $.post url, order: data.join ','


    onSaveSuccess: (data) =>
      # collID must be a string
      collID = @parentListView?.value()
      newCollection = @parentCollection?.get(collID).get(@childKey)

      # there is a currentCollection, but it doesn't match the model's collection
      if newCollection and newCollection != @model.collection
        #we need to remove the model from the previous collection
        #and add it to to the new one
        @model.collection.remove @model
        newCollection.add @model
        # also update the relationship to the collection
        # if we know how
        if @parentKey
          @model.set @parentKey, collID
      else
        newCollection = @model.collection

      #update all of the position attributes
      positions = [1..newCollection.length]
      _.each data.order, (id, index) ->
        newCollection.get(id)?.set 'position', positions[index]

      newCollection.sort()
      # finally, call reset to trigger a re-render
      newCollection.reset newCollection.models

      # close the dialog
      super
