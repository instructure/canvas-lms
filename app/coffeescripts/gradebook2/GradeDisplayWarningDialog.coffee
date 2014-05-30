define [
  'i18n!gradebook2'
  'jquery'
  'jst/GradeDisplayWarningDialog'
  'jqueryui/dialog'
], (I18n, $, gradeDisplayWarningDialogTemplate) ->

  class GradeDisplayWarningDialog
    constructor: (options) ->
      @options = options
      points_warning = I18n.t("grade_display_warning.points_text", "Students will also see their final grade as points. Are you sure you want to continue?")
      percent_warning = I18n.t("grade_display_warning.percent_text", "Students will also see their final grade as a percentage. Are you sure you want to continue?")
      locals =
        warning_text: if @options.showing_points then percent_warning else points_warning
      @$dialog = $ gradeDisplayWarningDialogTemplate(locals)
      @$dialog.dialog
        resizable: false
        width: 350
        buttons: [{
          text: I18n.t("grade_display_warning.cancel", "Cancel"), click: @cancel},
          {text: I18n.t("grade_display_warning.continue", "Continue"), click: @save}]

    save: () =>
      if @$dialog.find('#hide_warning').prop('checked')
        @options.checked_save()
      else
        @options.unchecked_save()
      @$dialog.remove()

    cancel: () =>
      @$dialog.remove()
