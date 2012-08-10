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
      terms_of_use:
        accepted:     I18n.t("errors.terms", "You must agree to the terms")

    pending: ->
      _.any @get('enrollments'), (e) -> e.enrollment_state in ['creation_pending', 'invited']

    hasEnrollmentType: (type) ->
      _.any @get('enrollments'), (e) -> e.type == type
