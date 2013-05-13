define [
  'compiled/models/User'
  'compiled/models/Pseudonym'
  'compiled/object/flatten'
], (User, Pseudonym, flatten) ->

  # normalize errors we get from POST /user (user creation API)
  registrationErrors = (errors, passwordPolicy = ENV.PASSWORD_POLICY) ->
    flatten
      user: User::normalizeErrors(errors.user)
      pseudonym: Pseudonym::normalizeErrors(errors.pseudonym, passwordPolicy)
      observee: Pseudonym::normalizeErrors(errors.observee, passwordPolicy)
    , arrays: false
