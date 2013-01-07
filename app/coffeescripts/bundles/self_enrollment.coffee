require [
  'jquery'
  'compiled/views/registration/SelfEnrollmentForm'
], ($, SelfEnrollmentForm) ->

  new SelfEnrollmentForm el: '#enroll_form'
