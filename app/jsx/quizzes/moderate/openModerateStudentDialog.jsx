define([
  'jquery',
  'i18n!quizzes.openModerateStudentDialog',
  'jqueryui/dialog',
  'compiled/jquery/fixDialogButtons' /* fix dialog formatting */
], ($, I18n) => {
  let openModerateStudentDialog = ($dialog, dialogWidth) => {
    let dialog = $dialog.dialog({
      title: I18n.t("Student Extensions"),
      width: dialogWidth
    }).fixDialogButtons();

    return dialog
  }

  return openModerateStudentDialog
})
