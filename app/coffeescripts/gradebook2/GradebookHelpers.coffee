define [
  'jquery'
  'underscore'
  'i18n!gradebook2'
  'jsx/gradebook/grid/constants'
], ($, _, I18n, GradebookConstants) ->
  FLASH_ERROR_CLASS: '.ic-flash-error'

  flashMaxLengthError: () ->
    $.flashError(I18n.t(
      'Note length cannot exceed %{maxLength} characters.',
      { maxLength: GradebookConstants.MAX_NOTE_LENGTH }
    ))

  maxLengthErrorShouldBeShown: (textareaLength) ->
    @textareaIsGreaterThanMaxLength(textareaLength) && @noErrorsOnPage()

  noErrorsOnPage: () ->
    $.find(@FLASH_ERROR_CLASS).length == 0

  textareaIsGreaterThanMaxLength: (textareaLength) ->
    !@textareaIsLessThanOrEqualToMaxLength(textareaLength)

  textareaIsLessThanOrEqualToMaxLength: (textareaLength) ->
    textareaLength <= GradebookConstants.MAX_NOTE_LENGTH

  gradeIsLocked: (assignment, env) ->
    return false unless env.GRADEBOOK_OPTIONS.multiple_grading_periods_enabled
    return false unless env.GRADEBOOK_OPTIONS.latest_end_date_of_admin_created_grading_periods_in_the_past
    return false unless env.current_user_roles
    return false if _.contains(env.current_user_roles, "admin")
    latest_end_date = new Date(env.GRADEBOOK_OPTIONS.latest_end_date_of_admin_created_grading_periods_in_the_past)
    assignment.due_at != null && assignment.due_at <= latest_end_date
