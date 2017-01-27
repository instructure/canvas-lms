import I18n from 'i18n!add_bank'
import $ from 'jquery'
import 'jquery.ajaxJSON' /* ajaxJSON */
import 'jquery.instructure_forms' /* formSubmit, getFormData, formErrors */
import 'jqueryui/dialog'
import 'jquery.instructure_misc_helpers' /* replaceTags */
import 'jquery.instructure_misc_plugins' /* confirmDelete, showIf, .dim */
import 'jquery.keycodes' /* keycodes */
import 'jquery.loadingImg' /* loadingImage */
import 'jquery.templateData' /* fillTemplateData, getTemplateData */

export default function addBank (bank) {
    var current_question_bank_id = $("#bank_urls .current_question_bank_id").text();
    if(bank.id == current_question_bank_id) { return; }
    var $dialog = $("#move_question_dialog");
    var $bank = $dialog.find("li.bank.blank:first").clone(true).removeClass('blank');

    $bank.find("input").attr('id', "question_bank_" + bank.id).val(bank.id);
    $bank.find("label").attr('for', "question_bank_" + bank.id)
      .find(".bank_name").text(bank.title || I18n.t('default_name', "No Name")).end()
      .find(".context_name").text(bank.cached_context_short_name);
    $bank.show().insertBefore($dialog.find("ul.banks .bank.blank:last"));
}
