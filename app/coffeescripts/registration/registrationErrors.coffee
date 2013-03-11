define [
  'compiled/models/User'
  'compiled/models/Pseudonym'
  'compiled/object/flatten'
], (User, Pseudonym, flatten) ->

  # normalize errors we get from POST /user (user creation API)
  registrationErrors = (errors) ->
    flatten
      user: User::normalizeErrors(errors.user)
      pseudonym: Pseudonym::normalizeErrors(errors.pseudonym)
      observee: Pseudonym::normalizeErrors(errors.observee)
    , arrays: false
