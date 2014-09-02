define [
  'ember-data'
  './user_serializer'
], (DS, UserSerializer) ->

  UnsubmittedStudentSerializer = UserSerializer.extend
    typeForRoot: (root) ->
      return @_super('unsubmitted_students')
