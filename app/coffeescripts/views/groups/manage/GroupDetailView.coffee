define [
  'i18n!GrouDetailpView'
  'Backbone'
  'jst/groups/manage/groupDetail'
], (I18n, {View}, template) ->

  class GroupDetailView extends View

    @optionProperty 'group'
    @optionProperty 'users'

    template: template

    els:
      '.group-summary': '$summary'

    attach: ->
      @group.on 'change', @render

    summary: ->
      count = @group.usersCount()
      if ENV.group_user_type is 'student'
        I18n.t "student_count", "student", count: count
      else
        I18n.t "user_count", "user", count: count

    toJSON: ->
      json = @group.toJSON()
      json.summary = @summary()
      json