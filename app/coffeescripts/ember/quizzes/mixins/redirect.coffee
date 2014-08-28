define [
  'ember'
  '../shared/environment'
  'i18n!quizzes_redirects'
  'compiled/jquery.rails_flash_notifications' # flash messages
], (Ember, env, I18n) ->

  Ember.Mixin.create

    validateRoute: (permission, path) ->
      if !env.get(permission)
        msg = I18n.t('no_access', 'Access denied. Redirected to a page you have access to.')
        @redirectTo(path, msg)

    redirectTo: (path, msg) ->
      @transitionTo(path)
      Ember.run.throttle(this, ( -> Ember.$.flashWarning(msg) ), 150)
