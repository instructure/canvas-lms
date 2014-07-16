define [
  'ember-data'
  './user_serializer'
], (DS, UserSerializer) ->

  SubmittedStudentSerializer = UserSerializer.extend
    typeForRoot: (root) ->
      return @_super('submitted_students')
