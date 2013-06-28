define [
  'i18n!groups'
  'Backbone'
  'jst/groups/manage/groupCategoryDetail'
], (I18n, {View}, template) ->

  class GroupCategoryDetailView extends View

    template: template

    attach: ->
      @collection.on 'add remove reset', @render

    toJSON: ->
      json = super
      json.groupCountText = I18n.t "group_count", {one: "1 group", other: "%{count} groups"}, count: @model.groupsCount()
      json
