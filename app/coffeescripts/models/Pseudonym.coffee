define [
  'i18n!pseudonym'
  'Backbone'
], (I18n, Backbone) ->

  class Pseudonym extends Backbone.Model

    errorMap: (policy) ->
      unique_id:
        too_short:    I18n.t("errors.required", "Required")
        too_long:     I18n.t("errors.too_long", "Can't exceed %{max} characters", {max: 100})
        invalid:      I18n.t("errors.invalid", "May only contain letters, numbers, or the following: %{characters}", {characters: ". + - _ @ ="})
        taken:        I18n.t("errors.taken", "Email already in use")
        bad_credentials: I18n.t("errors.bad_credentials", "Invalid username or password")
        not_email:    I18n.t("errors.not_email", "Not a valid email address")
      sis_user_id:
        too_long:     I18n.t("errors.too_long", "Can't exceed %{max} characters", {max: 255})
      password:
        too_short:    I18n.t("errors.too_short", "Must be at least %{min} characters", {min: policy.min_length})
        sequence:     I18n.t("errors.sequence", "Can't incude a run of more than %{max} characters (e.g. abcdef)", {max: policy.max_sequence})
        common:       I18n.t("errors.common", "Can't use common passwords (e.g. \"password\")")
        repeated:     I18n.t("errors.repeated", "Can't have the same character more than %{max} times in a row", {max: policy.max_repeats})
        confirmation: I18n.t("errors.mismatch", "Doesn't match")

    normalizeErrors: (errors, policy) ->
      if errors
        for type in ['unique_id', 'password'] when errors[type]?.length > 1
          # if there are multiple errors and one is "too_short", just show that
          too_short = null
          too_short = e for e in errors[type] when e.type is 'too_short'
          errors[type] = [too_short] if too_short
      super errors, policy
