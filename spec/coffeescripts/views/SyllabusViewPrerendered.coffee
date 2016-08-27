define [], ->
  ###
  [[ TEST DATA ]]

    <date1> - '2012-01-01T??:??:??-07:00'
    <date2> - '2012-01-11T??:??:??-07:00'
    <date3> - '2012-01-23T??:??:??-07:00'
    <date4> - '2012-01-30T??:??:??-07:00'
    <date5> - '2012-01-31T??:??:??-07:00'

    - Assignments (10 total) -
      2 on <date1>
      1 on <date2>
      1 on <date2> (overridden)
      1 on <date3> (overridden)
      1 on <date4> (overridden)
      2 on <date5> (overridden)
      2 undated

    - Appointment Groups (3 total) -
      2 on <date1>
      1 on <date3>

    - Calendar Events (3 total) -
      2 on <date1>
      1 on <date4>


  [[ REASONING ]]

    * Tests that multiple of each type can coalesce together (date1)
    * Tests overridden due dates coalescing with all event types (date2, date3, date4)
    * Tests overridden due dates collapsing entire dates when hidden (date5)
    * Tests undated events coalescing
  ###


  ### JSON ###
  assignments: [
    {
      'id': 'assignment_1'
      'title': 'Assignment One'
      'workflow_state': 'published'
      'start_at': '2012-01-31T20:00:00-07:00'
      'end_at': '2012-01-31T20:00:00-07:00'
      'url': 'http://localhost/api/v1/calendar_events/assignment_1'
      'html_url': 'http://localhost/courses/1/assignments/1'
      'type': 'assignment'
      "assignment_overrides": [
          {
              "all_day": false
              "all_day_date": "2012-01-31"
              "assignment_id": '1'
              "due_at": "2012-01-31T20:00:00-07:00"
              "id": '5'
              "title": "Assignment One Override Five"
              "student_ids": [
                  6
              ]
          }
      ]
    }
    {
      'id': 'assignment_2'
      'title': 'Assignment Two'
      'workflow_state': 'published'
      'start_at': '2012-01-01T13:00:00-07:00'
      'end_at': '2012-01-01T13:00:00-07:00'
      'url': 'http://localhost/api/v1/calendar_events/assignment_2'
      'html_url': 'http://localhost/courses/1/assignments/2'
      'type': 'assignment'
    }
    {
      'id': 'assignment_1'
      'title': 'Assignment One'
      'workflow_state': 'published'
      'start_at': '2012-01-23T10:00:00-07:00'
      'end_at': '2012-01-23T10:00:00-07:00'
      'url': 'http://localhost/api/v1/calendar_events/assignment_1'
      'html_url': 'http://localhost/courses/1/assignments/1'
      'type': 'assignment'
      "assignment_overrides": [
          {
              "all_day": false
              "all_day_date": "2012-01-23"
              "assignment_id": '1'
              "due_at": "2012-01-23T10:00:00-07:00"
              "id": '2'
              "title": "Assignment One Override Two"
              "student_ids": [
                  3
              ]
          }
      ]
    }
    {
      'id': 'assignment_4'
      'title': 'Assignment Four'
      'workflow_state': 'published'
      'start_at': null
      'end_at': null
      'url': 'http://localhost/api/v1/calendar_events/assignment_4'
      'html_url': 'http://localhost/courses/1/assignments/4'
      'type': 'assignment'
    }
    {
      'id': 'assignment_1'
      'title': 'Assignment One'
      'workflow_state': 'published'
      'start_at': '2012-01-30T10:00:00-07:00'
      'end_at': '2012-01-30T10:00:00-07:00'
      'url': 'http://localhost/api/v1/calendar_events/assignment_1'
      'html_url': 'http://localhost/courses/1/assignments/1'
      'type': 'assignment'
      "assignment_overrides": [
          {
              "all_day": false
              "all_day_date": "2012-01-30"
              "assignment_id": '1'
              "due_at": "2012-01-30T10:00:00-07:00"
              "id": '4'
              "title": "Assignment One Override Four"
              "student_ids": [
                  5
              ]
          }
      ]
    }
    {
      'id': 'assignment_5'
      'title': 'Assignment Five'
      'workflow_state': 'published'
      'start_at': null
      'end_at': null
      'url': 'http://localhost/api/v1/calendar_events/assignment_5'
      'html_url': 'http://localhost/courses/1/assignments/5'
      'type': 'assignment'
    }
    {
      'id': 'assignment_1'
      'title': 'Assignment One'
      'workflow_state': 'published'
      'start_at': '2012-01-31T10:00:00-07:00'
      'end_at': '2012-01-31T10:00:00-07:00'
      'url': 'http://localhost/api/v1/calendar_events/assignment_1'
      'html_url': 'http://localhost/courses/1/assignments/1'
      'type': 'assignment'
      "assignment_overrides": [
          {
              "all_day": false
              "all_day_date": "2012-01-31"
              "assignment_id": '1'
              "due_at": "2012-01-31T10:00:00-07:00"
              "id": '3'
              "title": "Assignment One Override Three"
              "student_ids": [
                  4
              ]
          }
      ]
    }
    {
      'id': 'assignment_3'
      'title': 'Assignment Three'
      'workflow_state': 'published'
      'start_at': '2012-01-11T11:00:00-07:00'
      'end_at': '2012-01-11T11:00:00-07:00'
      'url': 'http://localhost/api/v1/calendar_events/assignment_3'
      'html_url': 'http://localhost/courses/1/assignments/3'
      'type': 'assignment'
    }
    {
      'id': 'assignment_1'
      'title': 'Assignment One'
      'workflow_state': 'published'
      'start_at': '2012-01-11T10:00:00-07:00'
      'end_at': '2012-01-11T10:00:00-07:00'
      'url': 'http://localhost/api/v1/calendar_events/assignment_1'
      'html_url': 'http://localhost/courses/1/assignments/1'
      'type': 'assignment'
      "assignment_overrides": [
          {
              "all_day": false
              "all_day_date": "2012-01-11"
              "assignment_id": '1'
              "due_at": "2012-01-11T10:00:00-07:00"
              "id": '1'
              "title": "Assignment One Override One"
              "student_ids": [
                  2
              ]
          }
      ]
    }
    {
      'id': 'assignment_1'
      'title': 'Assignment One'
      'workflow_state': 'published'
      'start_at': '2012-01-01T10:00:00-07:00'
      'end_at': '2012-01-01T10:00:00-07:00'
      'url': 'http://localhost/api/v1/calendar_events/assignment_1'
      'html_url': 'http://localhost/courses/1/assignments/1'
      'type': 'assignment'
    }
  ]

  appointment_groups: [
    {
      'id': '3'
      'title': 'Appointment Group Three'
      'workflow_state': 'active'
      'start_at': '2012-01-23T15:00:00-07:00'
      'end_at': '2012-01-23T17:30:00-07:00'
      'url': 'http://localhost/api/v1/appointment_groups/3'
      'html_url': 'http://localhost/appointment_groups/3'
      'max_appointments_per_participant': 1
      'min_appointments_per_participant': 1
      'participant_visibility': 'private'
      'participants_per_appointment': null
      'context_codes': [
          'course_1'
      ]
      'requiring_action': false
      'appointments_count': 10
      'participant_type': 'User'
      'type': 'event'
    }
    {
      'id': '2'
      'title': 'Appointment Group Two'
      'workflow_state': 'active'
      'start_at': '2012-01-01T16:00:00-07:00'
      'end_at': '2012-01-01T18:00:00-07:00'
      'url': 'http://localhost/api/v1/appointment_groups/2'
      'html_url': 'http://localhost/appointment_groups/2'
      'max_appointments_per_participant': 1
      'min_appointments_per_participant': 1
      'participant_visibility': 'private'
      'participants_per_appointment': null
      'context_codes': [
          'course_1'
      ]
      'requiring_action': false
      'appointments_count': 8
      'participant_type': 'Group'
      'type': 'event'
    }
    {
      'id': '1'
      'title': 'Appointment Group One'
      'workflow_state': 'active'
      'start_at': '2012-01-01T08:00:00-07:00'
      'end_at': '2012-01-01T10:00:00-07:00'
      'url': 'http://localhost/api/v1/appointment_groups/1'
      'html_url': 'http://localhost/appointment_groups/1'
      'max_appointments_per_participant': 1
      'min_appointments_per_participant': 1
      'participant_visibility': 'private'
      'participants_per_appointment': null
      'context_codes': [
          'course_1'
      ]
      'requiring_action': false
      'appointments_count': 8
      'participant_type': 'User'
      'type': 'event'
    }
  ]

  events: [
    {
      'id': '2'
      'title': 'Event Two'
      'workflow_state': 'active'
      'start_at': '2012-01-01T19:30:00-07:00'
      'end_at': '2012-01-01T19:30:00-07:00'
      'url': 'http://localhost/api/v1/calendar_events/2'
      'html_url': 'http://localhost/calendar?event_id=2&include_contexts=course_1'
      'type': 'event'
    }
    {
      'id': '3'
      'title': 'Event Three'
      'workflow_state': 'active'
      'start_at': '2012-01-30T19:30:00-07:00'
      'end_at': '2012-01-30T19:30:00-07:00'
      'url': 'http://localhost/api/v1/calendar_events/3'
      'html_url': 'http://localhost/calendar?event_id=3&include_contexts=course_1'
      'type': 'event'
    }
    {
      'id': '1'
      'title': 'Event One'
      'workflow_state': 'active'
      'start_at': '2012-01-01T13:30:00-07:00'
      'end_at': '2012-01-01T13:30:00-07:00'
      'url': 'http://localhost/api/v1/calendar_events/1'
      'html_url': 'http://localhost/calendar?event_id=1&include_contexts=course_1'
      'type': 'event'
    }
    {
      'id': '4'
      'title': 'Hidden Event'
      'workflow_state': 'active'
      'start_at': '2012-01-01T13:30:00-07:00'
      'end_at': '2012-01-30T19:30:00-07:00'
      'url': 'http://localhost/api/v1/calendar_events/4'
      'html_url': 'http://localhost/calendar?event_id=4&include_contexts=course_1'
      'hidden': true
      'type': 'event'
    }
  ]


  ### HTML ###
  jumpToToday: '''<a href="#" class="jump_to_today_link">Jump to Today</a>'''

  syllabusContainer: '''<div id="syllabusContainer"/>'''

  miniMonthDay: (year, month, day, currentMonth = 1, currentDay = 1) ->
    month = ("0" + month).slice(-2)
    day = ("0" + day).slice(-2)
    """
            <td id="mini_day_#{year}_#{month}_#{day}" class="mini_calendar_day day #{if month != currentMonth then "other_month " + (if (month + 1) % 12 == currentMonth then "previous_month" else "next_month") else "current_month"} #{if currentDay == day and currentMonth == month then "today" else ""} date_#{month}_#{day}_#{year}">
              <div class="day_wrapper">
                <span class="day_number" title="#{month}/#{day}/#{year}">#{day}</span>
                <span class="screenreader-only previous_month_text">Previous month</span>
                <span class="screenreader-only next_month_text">Next month</span>
                <span class="screenreader-only today_text">Today</span>
                <span class="screenreader-only event_link_text">Click to view event details</span>
              </div>
            </td>
    """

  miniMonth: -> """
    <div class="mini_month" aria-hidden="true">
      <div class="mini-cal-header">
        <button class="prev_month_link Button Button--icon-action"><i class="icon-arrow-open-left"></i><span class="screenreader-only">Prev month</span></button>
        <button class="next_month_link Button Button--icon-action"><i class="icon-arrow-open-right"></i><span class="screenreader-only">Next month</span></button>
        <span class="mini-cal-month-and-year">
          <span class="month_name">January</span>
          <span class="year_number">2012</span>
        </span>
      </div>
      <div style="display: none;">
        <span class="month_number">1</span>
      </div>
      <table class="mini_calendar" cellspacing="0">
        <caption class="screenreader-only">Calendar</caption>
        <thead>
          <tr>
            <th scope="col">
              <span class="screenreader-only">
                Sunday
              </span>
            </th>
            <th scope="col">
              <span class="screenreader-only">
                Monday
              </span>
            </th>
            <th scope="col">
              <span class="screenreader-only">
                Tuesday
              </span>
            </th>
            <th scope="col">
              <span class="screenreader-only">
                Wednesday
              </span>
            </th>
            <th scope="col">
              <span class="screenreader-only">
                Thursday
              </span>
            </th>
            <th scope="col">
              <span class="screenreader-only">
                Friday
              </span>
            </th>
            <th scope="col">
              <span class="screenreader-only">
                Saturday
              </span>
            </th>
          </tr>
        </thead>
        <tbody><tr class="mini_calendar_week">
          #{(@miniMonthDay(2011, 12, day) for day in [25..31]).join("\n")}
        </tr>
        <tr class="mini_calendar_week">
          #{(@miniMonthDay(2012, 1, day) for day in [1..7]).join("\n")}
        </tr>
        <tr class="mini_calendar_week">
          #{(@miniMonthDay(2012, 1, day) for day in [8..14]).join("\n")}
        </tr>
        <tr class="mini_calendar_week">
          #{(@miniMonthDay(2012, 1, day) for day in [15..21]).join("\n")}
        </tr>
        <tr class="mini_calendar_week">
          #{(@miniMonthDay(2012, 1, day) for day in [22..28]).join("\n")}
        </tr>
        <tr class="mini_calendar_week">
          #{(@miniMonthDay(2012, 1, day) for day in [29..31]).join("\n")}
          #{(@miniMonthDay(2012, 2, day) for day in [1..4]).join("\n")}
        </tr>
      </tbody></table>
    </div>
  """
