define [
  'i18n!discussions'
  'underscore'
  'Backbone'
  'jst/DiscussionTopics/discussion'
], (I18n, _, {View}, template) ->

  class DiscussionView extends View
    template: template

    tagName: 'li'

    className: 'discussion'

    messages:
      confirm: I18n.t('confirm_delete_discussion_topic', 'Are you sure you want to delete this discussion topic?')
      delete:  I18n.t('delete', 'Delete')
      lock:    I18n.t('lock', 'Lock')
      unlock:  I18n.t('unlock', 'Unlock')

    events:
      'click .icon-lock':  'lock'
      'click .icon-trash': 'delete'
      'click': 'onClick'

    initialize: (options) ->
      super
      @attachModel()

    attachModel: ->
      @model.on('change:hidden', @hide)

    lock: (e) =>
      e.preventDefault()
      key = if @model.get('locked') then 'lock' else 'unlock'
      @model.updateOneAttribute('locked', !@model.get('locked'))
      $(e.target).text(@messages[key])

    delete: (e) =>
      e.preventDefault()
      if confirm(@messages.confirm)
        @model.destroy()
        @$el.remove()

    onClick: (e) ->
      return if _.contains(['A', 'I'], e.target.nodeName)
      window.location = @model.get('html_url')

    hide: =>
      @$el.toggle(!@model.get('hidden'))

    toJSON: ->
      @model.toJSON()
