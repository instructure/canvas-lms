require [
  'jquery'
  'compiled/views/registration/SelfEnrollmentForm'
], ($, SelfEnrollmentForm) ->

  options = $.extend {}, ENV.SELF_ENROLLMENT_OPTIONS ? {}, el: '#enroll_form'
  new SelfEnrollmentForm options
