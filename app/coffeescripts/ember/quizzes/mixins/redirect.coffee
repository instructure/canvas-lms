define [
  'ember'
  '../shared/environment'
  'i18n!quizzes_redirects'
  'compiled/jquery.rails_flash_notifications' # flash messages
], (Em, env, I18n) ->

  Em.Mixin.create

    validateRoute: (permission, redirectTo) ->
      if !env.get(permission)
        this.transitionTo(redirectTo)
        Ember.run.throttle(this, @displayRedirect, 150)

    displayRedirect: ->
      Ember.$.flashWarning I18n.t('no_access', 'Access denied. Redirected to a page you have access to.')

