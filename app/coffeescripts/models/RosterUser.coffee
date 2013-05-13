define ['compiled/models/User'], (User) ->

  class RosterUser extends User

    defaults:
      avatar_url: '/images/messages/avatar-50.png'

    computedAttributes: [
      'sections'
      {name: 'html_url', deps: ['enrollments']}
    ]

    html_url: ->
      @get('enrollments')[0].html_url

    sections: ->
      return [] unless @collection?.sections?
      {sections} = @collection
      for {course_section_id} in @get('enrollments')
        sections.get(course_section_id).attributes

