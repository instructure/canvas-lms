define ['ember'], (Ember) ->
  UsersController = Ember.ArrayController.extend

    usersPath: "/api/v1/courses/#{ENV.course_id}/users"
    itemController: 'user'
