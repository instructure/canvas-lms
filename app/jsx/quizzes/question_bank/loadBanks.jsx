import I18n from 'i18n!load_bank'
import $ from 'jquery'
import addBank from 'jsx/quizzes/question_bank/addBank'
import 'jquery.ajaxJSON' /* ajaxJSON */
import 'jquery.instructure_forms' /* formSubmit, getFormData, formErrors */
import 'jqueryui/dialog'
import 'jquery.instructure_misc_helpers' /* replaceTags */
import 'jquery.instructure_misc_plugins' /* confirmDelete, showIf, .dim */
import 'jquery.keycodes' /* keycodes */
import 'jquery.loadingImg' /* loadingImage */
import 'jquery.templateData' /* fillTemplateData, getTemplateData */

export default function loadBanks () {
    var url = $("#bank_urls .managed_banks_url").attr('href');
    var $dialog = $("#move_question_dialog");
    $dialog.find("li.message").text(I18n.t('loading_banks', "Loading banks..."));
    $.ajaxJSON(url, 'GET', {}, function(data) {
      for(var idx = 0; idx < data.length; idx++) {
        addBank(data[idx].assessment_question_bank);
      }
      $dialog.addClass('loaded');
      $dialog.find("li.bank.blank").show();
      $dialog.find("li.message").hide();
    }, function(data) {
      $dialog.find("li.message").text(I18n.t("error_loading_banks", "Error loading banks"));
    });
}
