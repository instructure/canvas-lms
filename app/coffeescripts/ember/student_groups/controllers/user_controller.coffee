define [
  'i18n!student_groups'
  'ember'
  'ic-ajax'
], (I18n, Ember, ajax) ->

  UserController = Ember.ObjectController.extend

    idString:(->
      "invitees_#{@get('id')}"
    ).property('id')

    isCurrentUser: (->
      ENV.current_user_id == @get('id')
    ).property('id')

    invite:false
