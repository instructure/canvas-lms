import $ from 'jquery'
import SelfEnrollmentForm from 'compiled/views/registration/SelfEnrollmentForm'

const options = $.extend({}, ENV.SELF_ENROLLMENT_OPTIONS != null ? ENV.SELF_ENROLLMENT_OPTIONS : {}, {el: '#enroll_form'})
new SelfEnrollmentForm(options)
