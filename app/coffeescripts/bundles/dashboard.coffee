require [
  'dashboard'
  'compiled/registration/incompleteRegistrationWarning'
], (dashboard, incompleteRegistrationWarning) ->
  $ ->
    incompleteRegistrationWarning(ENV.USER_EMAIL) if ENV.INCOMPLETE_REGISTRATION
