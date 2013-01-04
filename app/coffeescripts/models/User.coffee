define [
  'i18n!user'
  'underscore'
  'Backbone'
], (I18n, _, Backbone) ->

  class User extends Backbone.Model

    errorMap:
      name:
        blank:        I18n.t("errors.required", "Required")
        too_long:     I18n.t("errors.too_long", "Can't exceed %{max} characters", {max: 255})
      birthdate:
        blank:        I18n.t("errors.required", "Required")
        too_young:    I18n.t("errors.too_young", "Too young")
      self_enrollment_code:
        blank:        I18n.t("errors.required", "Required")
        invalid:      I18n.t("errors.invalid_code", "Invalid code")
        already_enrolled: I18n.t("errors.already_enrolled", "You are already enrolled in this course")
        full:         I18n.t("errors.course_full", "This course is full")
      terms_of_use:
        accepted:     I18n.t("errors.terms", "You must agree to the terms")

    pending: (role) ->
      _.any @get('enrollments'), (e) -> e.role == role && e.enrollment_state in ['creation_pending', 'invited']

    hasEnrollmentType: (type, role) ->
      _.any @get('enrollments'), (e) -> e.role == role && e.type == type

    findEnrollmentWithRole: (role) ->
      _.find @get('enrollments'), (e) -> e.role == role

    allEnrollmentsWithRole: (role) ->
      _.select @get('enrollments'), (e) -> e.role == role
