define ['Backbone', 'underscore'], ({Model}, _) ->

  class CreateUserList extends Model

    defaults:
      roles: null
      sections: null
      course_section_id: null
      enrollment_type: null
      user_list: null
      readURL: null
      updateURL: null
      step: 1
      enrolledUsers: null

    present: ->
      json = @attributes
      json.course_section_id = parseInt json.course_section_id, 10
      json

    toJSON: ->
      attrs = [
        'course_section_id'
        'enrollment_type'
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

