define [
  'i18n!roster'
  'Backbone'
  'jst/courses/roster/index'
  'compiled/views/ValidatedMixin'
], (I18n, Backbone, template, ValidatedMixin) ->

  class RosterView extends Backbone.View

    @mixin ValidatedMixin

    @child 'usersView', '[data-view=users]'

    @child 'inputFilterView', '[data-view=inputFilter]'

    @child 'roleSelectView', '[data-view=roleSelect]'

    @child 'createUsersView', '[data-view=createUsers]'

    @optionProperty 'roles'

    @optionProperty 'permissions'

    template: template

    els:
      '#addUsers': '$addUsersButton'

    afterRender: ->
      # its a child view so it gets rendered automatically, need to stop it
      @createUsersView.hide()
      # its trigger would not be rendered yet, set it manually
      @createUsersView.setTrigger @$addUsersButton

    attach: ->
      @collection.on 'setParam deleteParam', @fetch
      @createUsersView.on 'close', @fetchOnCreateUsersClose

    fetchOnCreateUsersClose: =>
      @collection.fetch() if @createUsersView.hasUsers()

    fetch: =>
      @lastRequest?.abort()
      @lastRequest = @collection.fetch().fail @onFail

    toJSON: -> this

    onFail: (xhr) =>
      return if xhr.statusText is 'abort'
      parsed = $.parseJSON xhr.responseText
      message = if parsed?.message is "search_term of 3 or more characters is required"
        I18n.t('greater_than_three', 'Please enter a search term with three or more characters')
      else
        I18n.t('unknown_error', 'Something went wrong with your search, please try again.')
      @showErrors search_term: [{message}]

