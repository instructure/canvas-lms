define [
  'ember'
  'i18n!draft_state'
], (Em, I18n) ->

  Em.Component.extend
    attributeBindings: [ 'aria-disabled', 'disabled', 'title', 'data-tooltip' ]

    'data-tooltip': 'top'

    title: (->
      if @get 'disabled'
        @get 'disabled-message'
      else if @get('is-published')
        I18n.t('unpublish', 'Unpublish')
      else
        I18n.t('publish', 'Publish')
    ).property('is-published')

    actions:
      changePublished: ->
        return if @get 'disabled'
        if @get('published')
          @sendAction 'on-unpublish'
        else
          @sendAction 'on-publish'


    'disabled-message': I18n.t('cant_unpublish_when_students_submit', "Can't unpublish if there are student submissions")
