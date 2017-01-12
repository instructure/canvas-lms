define ['compiled/models/User', 'compiled/util/secondsToTime', 'underscore'], (User, secondsToTime, _) ->

  class RosterUser extends User

    defaults:
      avatar_url: '/images/messages/avatar-50.png'

    computedAttributes: [
      'sections'
      'total_activity_string'
      {name: 'html_url', deps: ['enrollments']}
    ]

    html_url: ->
      @get('enrollments')[0]?.html_url

    sections: ->
      return [] unless @collection?.sections?
      {sections} = @collection
      user_sections = []
      for {course_section_id} in @get('enrollments')
        user_section = sections.get(course_section_id)
        user_sections.push(user_section.attributes) if user_section
      user_sections

    total_activity_string: ->
      if time = _.max(_.map(@get('enrollments'), (e) -> e.total_activity_time))
        secondsToTime(time)
      else
        ''

