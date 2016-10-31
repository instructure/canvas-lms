define [
  'jquery'
  'i18n!gradebook2'
  'jsx/gradebook/shared/constants'
], ($, I18n, GradebookConstants) ->
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
