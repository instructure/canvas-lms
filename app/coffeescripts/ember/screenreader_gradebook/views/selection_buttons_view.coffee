define [
  'ember'
  'i18n!sr_gradebook'
], (Ember, I18n) ->

  SelectionButtonsView = Ember.View.extend
    templateName: 'content_selection/selection_buttons'

    list: null
    type: null
    selected: null

    classPath: (->
      @get('type') + "_navigation"
    ).property('type')

    previousLabel:(->
      type = @get('type').capitalize()
      I18n.t("previous_object", "Previous %{type}", {type: type})
    ).property('type')

    nextLabel: (->
      type = @get('type').capitalize()
      I18n.t("next_object", "Next %{type}", {type: type})
    ).property('type')

    disablePreviousButton: Ember.computed.lte('currentIndex', 0)

    disableNextButton:(->
      next = @get('list').objectAt(@get('currentIndex') + 1)
      !(@get('list.length') and next)
    ).property('currentIndex','list.@each')

    currentIndex:(->
      @get('list').indexOf(@get('selected'))
    ).property('selected','list.@each')

    actions:
      selectItem: (goTo) ->
        index = @get('currentIndex')
        list = @get('list')
        item = null

        if goTo == 'previous'
          item = list.objectAt(index - 1)
          unless list.objectAt(index - 2)
            @$(".next_object").focus()
        if goTo == 'next'
          item = list.objectAt(index + 1)
          unless list.objectAt(index + 2)
            @$(".previous_object").focus()

        if item
          @set('selected', item)
          @get('controller').send('selectItem', @get('type'), item)
