define [
  'i18n!unassigned'
  'Backbone'
  'jst/groups/manage/unassigned'
  'compiled/views/ValidatedMixin'
], (I18n, {View}, template, ValidatedMixin) ->

  class UnassignedView extends View

    @mixin ValidatedMixin

    @child 'usersView', '[data-view=users]'

    @child 'inputFilterView', '[data-view=inputFilter]'

    className: 'assign-to-group-menu popover right content-top horizontal'

    template: template

    attach: ->
      @collection.on 'setParam deleteParam', @fetch

    fetch: =>
      @lastRequest?.abort()
      @lastRequest = @collection.fetch()

    toJSON: ->
      users: @collection.toJSON()


