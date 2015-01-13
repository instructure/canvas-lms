define ['Backbone', 'underscore'], ({Model}, _) ->

  class CreateUserList extends Model

    defaults:
      roles: null
      sections: null
      course_section_id: null
      role_id: null
      user_list: null
      readURL: null
      updateURL: null
      step: 1
      enrolledUsers: null

    present: ->
      @attributes

    toJSON: ->
      attrs = [
        'course_section_id'
        'role_id'
        'user_list'
        'limit_privileges_to_course_section'
      ]
      json = _.pick @attributes, attrs...

    url: ->
      if @get('step') is 1
        @get 'readURL'
      else
        @get 'updateURL'

    incrementStep: ->
      @set 'step', @get('step') + 1

    startOver: ->
      @set 'users', null
      @set 'step', 1

    parse: (data) ->
      if _.isArray(data)
        enrolledUsers: data
      else
        data

