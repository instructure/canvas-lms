define ['support/jquery.mockjax'], ($) ->
  $.mockjax
    url:  /\/api\/v1\/courses\/\d+(\?.+)?$/
    responseText: [
      name: "teacher's test course"
      id: 1
      enrollments: [ type: "teacher" ]
      course_code: "RY 101"
      sis_course_id: null
      calendar:
        ics: "http://example.com/feeds/calendars/course_e3b41bfc0e6665062b8d442e0b7096f49d1f3859.ics"
    ,
      name: "My Course"
      id: 8
      enrollments: [ type: "ta" ]
      course_code: "Course-101"
      sis_course_id: null
      calendar:
        ics: "http://example.com/feeds/calendars/course_KdkLMSWISSmVHhX5T5hxjNE1lUDLF0zXfojIUISE.ics"
    ,
      name: "corse i am a student in"
      id: 9
      enrollments: [ type: "student" ]
      course_code: "criasi"
      sis_course_id: null
      calendar:
        ics: "http://example.com/feeds/calendars/course_PVeprcyWyJnk4evwazeGrDGBcTdTFCm2WZVRTlyE.ics"
     ]
