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
      'assignment':
        'id': '1'
        'due_at': '2012-01-31T20:00:00-07:00'
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
      'assignment':
        'id': '2'
        'due_at': '2012-01-01T13:00:00-07:00'
    }
    {
      'id': 'assignment_1'
      'title': 'Assignment One'
      'workflow_state': 'published'
      'start_at': '2012-01-23T10:00:00-07:00'
      'end_at': '2012-01-23T10:00:00-07:00'
      'url': 'http://localhost/api/v1/calendar_events/assignment_1'
      'html_url': 'http://localhost/courses/1/assignments/1'
      'assignment':
        'id': '1'
        'due_at': '2012-01-23T10:00:00-07:00'
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
      'assignment':
        'id': '4'
        'due_at': null
    }
    {
      'id': 'assignment_1'
      'title': 'Assignment One'
      'workflow_state': 'published'
      'start_at': '2012-01-30T10:00:00-07:00'
      'end_at': '2012-01-30T10:00:00-07:00'
      'url': 'http://localhost/api/v1/calendar_events/assignment_1'
      'html_url': 'http://localhost/courses/1/assignments/1'
      'assignment':
        'id': '1'
        'due_at': '2012-01-30T10:00:00-07:00'
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
      'assignment':
        'id': '5'
        'due_at': null
    }
    {
      'id': 'assignment_1'
      'title': 'Assignment One'
      'workflow_state': 'published'
      'start_at': '2012-01-31T10:00:00-07:00'
      'end_at': '2012-01-31T10:00:00-07:00'
      'url': 'http://localhost/api/v1/calendar_events/assignment_1'
      'html_url': 'http://localhost/courses/1/assignments/1'
      'assignment':
        'id': '1'
        'due_at': '2012-01-31T10:00:00-07:00'
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
      'assignment':
        'id': '3'
        'due_at': '2012-01-11T11:00:00-07:00'
    }
    {
      'id': 'assignment_1'
      'title': 'Assignment One'
      'workflow_state': 'published'
      'start_at': '2012-01-11T10:00:00-07:00'
      'end_at': '2012-01-11T10:00:00-07:00'
      'url': 'http://localhost/api/v1/calendar_events/assignment_1'
      'html_url': 'http://localhost/courses/1/assignments/1'
      'assignment':
        'id': '1'
        'due_at': '2012-01-11T10:00:00-07:00'
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
      'assignment':
        'id': '1'
        'due_at': '2012-01-01T10:00:00-07:00'
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
    }
    {
      'id': '3'
      'title': 'Event Three'
      'workflow_state': 'active'
      'start_at': '2012-01-30T19:30:00-07:00'
      'end_at': '2012-01-30T19:30:00-07:00'
      'url': 'http://localhost/api/v1/calendar_events/3'
      'html_url': 'http://localhost/calendar?event_id=3&include_contexts=course_1'
    }
    {
      'id': '1'
      'title': 'Event One'
      'workflow_state': 'active'
      'start_at': '2012-01-01T13:30:00-07:00'
      'end_at': '2012-01-01T13:30:00-07:00'
      'url': 'http://localhost/api/v1/calendar_events/1'
      'html_url': 'http://localhost/calendar?event_id=1&include_contexts=course_1'
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
    }
  ]


  ### HTML ###
  jumpToToday: '''<a href="#" class="jump_to_today_link">Jump to Today</a>'''

  syllabusContainer: '''<div id="syllabusContainer"/>'''

  miniMonth: '''
    <div class="mini_month" aria-hidden="true">
      <div class="mini-cal-header">
        <a href="#" class="prev_month_link"><i class="icon-arrow-left standalone-icon"></i></a>
        <a href="#" class="next_month_link"><i class="icon-arrow-right standalone-icon"></i></a>
        <span class="mini-cal-month-and-year">
          <span class="month_name">January</span>
          <span class="year_number">2012</span>
        </span>
      </div>
      <div style="display: none;">
        <span class="month_number">1</span>
      </div>
      <table class="mini_calendar" cellspacing="0">
        <tbody><tr class="mini_calendar_week">
            <td id="mini_day_2011_12_25" class="mini_calendar_day day other_month date_12_25_2011">
              <span class="day_number" title="12/25/2011">25</span>
            </td>
            <td id="mini_day_2011_12_26" class="mini_calendar_day day other_month date_12_26_2011">
              <span class="day_number" title="12/26/2011">26</span>
            </td>
            <td id="mini_day_2011_12_27" class="mini_calendar_day day other_month date_12_27_2011">
              <span class="day_number" title="12/27/2011">27</span>
            </td>
            <td id="mini_day_2011_12_28" class="mini_calendar_day day other_month date_12_28_2011">
              <span class="day_number" title="12/28/2011">28</span>
            </td>
            <td id="mini_day_2011_12_29" class="mini_calendar_day day other_month date_12_29_2011">
              <span class="day_number" title="12/29/2011">29</span>
            </td>
            <td id="mini_day_2011_12_30" class="mini_calendar_day day other_month date_12_30_2011">
              <span class="day_number" title="12/30/2011">30</span>
            </td>
            <td id="mini_day_2011_12_31" class="mini_calendar_day day other_month date_12_31_2011">
              <span class="day_number" title="12/31/2011">31</span>
            </td>
        </tr>
        <tr class="mini_calendar_week">
            <td id="mini_day_2012_01_01" class="mini_calendar_day day current_month today date_01_01_2012">
              <span class="day_number" title="01/01/2012">1</span>
            </td>
            <td id="mini_day_2012_01_02" class="mini_calendar_day day current_month date_01_02_2012">
              <span class="day_number" title="01/02/2012">2</span>
            </td>
            <td id="mini_day_2012_01_03" class="mini_calendar_day day current_month date_01_02_2012">
              <span class="day_number" title="01/03/2012">3</span>
            </td>
            <td id="mini_day_2012_01_04" class="mini_calendar_day day current_month date_01_04_2012">
              <span class="day_number" title="01/04/2012">4</span>
            </td>
            <td id="mini_day_2012_01_05" class="mini_calendar_day day current_month date_01_05_2012">
              <span class="day_number" title="01/05/2012">5</span>
            </td>
            <td id="mini_day_2012_01_06" class="mini_calendar_day day current_month date_01_06_2012">
              <span class="day_number" title="01/06/2012">6</span>
            </td>
            <td id="mini_day_2012_01_07" class="mini_calendar_day day current_month date_01_07_2012">
              <span class="day_number" title="01/07/2012">7</span>
            </td>
        </tr>
        <tr class="mini_calendar_week">
            <td id="mini_day_2012_01_08" class="mini_calendar_day day current_month date_01_08_2012">
              <span class="day_number" title="01/08/2012">8</span>
            </td>
            <td id="mini_day_2012_01_09" class="mini_calendar_day day current_month date_01_09_2012">
              <span class="day_number" title="01/09/2012">9</span>
            </td>
            <td id="mini_day_2012_01_10" class="mini_calendar_day day current_month date_01_10_2012">
              <span class="day_number" title="01/10/2012">10</span>
            </td>
            <td id="mini_day_2012_01_11" class="mini_calendar_day day current_month date_01_11_2012">
              <span class="day_number" title="01/11/2012">11</span>
            </td>
            <td id="mini_day_2012_01_12" class="mini_calendar_day day current_month date_01_12_2012">
              <span class="day_number" title="01/12/2012">12</span>
            </td>
            <td id="mini_day_2012_01_13" class="mini_calendar_day day current_month date_01_13_2012">
              <span class="day_number" title="01/13/2012">13</span>
            </td>
            <td id="mini_day_2012_01_14" class="mini_calendar_day day current_month date_01_14_2012">
              <span class="day_number" title="01/14/2012">14</span>
            </td>
        </tr>
        <tr class="mini_calendar_week">
            <td id="mini_day_2012_01_15" class="mini_calendar_day day current_month date_01_15_2012">
              <span class="day_number" title="01/15/2012">15</span>
            </td>
            <td id="mini_day_2012_01_16" class="mini_calendar_day day current_month date_01_16_2012">
              <span class="day_number" title="01/16/2012">16</span>
            </td>
            <td id="mini_day_2012_01_17" class="mini_calendar_day day current_month date_01_17_2012">
              <span class="day_number" title="01/17/2012">17</span>
            </td>
            <td id="mini_day_2012_01_18" class="mini_calendar_day day current_month date_01_18_2012">
              <span class="day_number" title="01/18/2012">18</span>
            </td>
            <td id="mini_day_2012_01_19" class="mini_calendar_day day current_month date_01_19_2012">
              <span class="day_number" title="01/19/2012">19</span>
            </td>
            <td id="mini_day_2012_01_20" class="mini_calendar_day day current_month date_01_20_2012">
              <span class="day_number" title="01/20/2012">20</span>
            </td>
            <td id="mini_day_2012_01_21" class="mini_calendar_day day current_month date_01_21_2012">
              <span class="day_number" title="01/21/2012">21</span>
            </td>
        </tr>
        <tr class="mini_calendar_week">
            <td id="mini_day_2012_01_22" class="mini_calendar_day day current_month date_01_22_2012">
              <span class="day_number" title="01/22/2012">22</span>
            </td>
            <td id="mini_day_2012_01_23" class="mini_calendar_day day current_month date_01_23_2012">
              <span class="day_number" title="01/23/2012">23</span>
            </td>
            <td id="mini_day_2012_01_24" class="mini_calendar_day day current_month date_01_24_2012">
              <span class="day_number" title="01/24/2012">24</span>
            </td>
            <td id="mini_day_2012_01_25" class="mini_calendar_day day current_month date_01_25_2012">
              <span class="day_number" title="01/25/2012">25</span>
            </td>
            <td id="mini_day_2012_01_26" class="mini_calendar_day day current_month date_01_26_2012">
              <span class="day_number" title="01/26/2012">26</span>
            </td>
            <td id="mini_day_2012_01_27" class="mini_calendar_day day current_month date_01_27_2012">
              <span class="day_number" title="01/27/2012">27</span>
            </td>
            <td id="mini_day_2012_01_28" class="mini_calendar_day day current_month date_01_28_2012">
              <span class="day_number" title="01/28/2012">28</span>
            </td>
        </tr>
        <tr class="mini_calendar_week">
            <td id="mini_day_2012_01_29" class="mini_calendar_day day current_month date_01_29_2012">
              <span class="day_number" title="01/29/2012">29</span>
            </td>
            <td id="mini_day_2012_01_30" class="mini_calendar_day day current_month date_01_30_2012">
              <span class="day_number" title="01/30/2012">30</span>
            </td>
            <td id="mini_day_2012_01_31" class="mini_calendar_day day current_month date_01_31_2012">
              <span class="day_number" title="01/31/2012">31</span>
            </td>
            <td id="mini_day_2012_02_01" class="mini_calendar_day day other_month date_02_01_2012">
              <span class="day_number" title="02/01/2012">1</span>
            </td>
            <td id="mini_day_2012_02_02" class="mini_calendar_day day other_month date_02_02_2012">
              <span class="day_number" title="02/02/2012">2</span>
            </td>
            <td id="mini_day_2012_02_03" class="mini_calendar_day day other_month date_02_03_2012">
              <span class="day_number" title="02/03/2012">3</span>
            </td>
            <td id="mini_day_2012_02_04" class="mini_calendar_day day other_month date_02_04_2012">
              <span class="day_number" title="02/04/2012">4</span>
            </td>
        </tr>
      </tbody></table>
    </div>
  '''
