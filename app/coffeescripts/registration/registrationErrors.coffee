define [
  'compiled/models/User'
  'compiled/models/Pseudonym'
  'compiled/object/flatten'
], (User, Pseudonym, flatten) ->

  # normalize errors we get from POST /user (user creation API)
  registrationErrors = (errors) ->
    errors = flatten
      user: User::normalizeErrors(errors.user)
      pseudonym: Pseudonym::normalizeErrors(errors.pseudonym)
      observee: Pseudonym::normalizeErrors(errors.observee)
    , arrays: false
    if errors['user[birthdate]']
      errors['user[birthdate(1i)]'] = errors['user[birthdate]']
      delete errors['user[birthdate]']
    errors
