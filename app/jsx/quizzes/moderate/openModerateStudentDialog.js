import $ from 'jquery'
import I18n from 'i18n!quizzes.openModerateStudentDialog'
import 'jqueryui/dialog'
import 'compiled/jquery/fixDialogButtons'
  let openModerateStudentDialog = ($dialog, dialogWidth) => {
    let dialog = $dialog.dialog({
      title: I18n.t("Student Extensions"),
      width: dialogWidth
    }).fixDialogButtons();

    return dialog
  }

export default openModerateStudentDialog
