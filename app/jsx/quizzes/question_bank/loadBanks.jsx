define([
  'i18n!load_bank',
  'jquery' /* $ */,
  'jsx/quizzes/question_bank/addBank',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_forms' /* formSubmit, getFormData, formErrors */,
  'jqueryui/dialog',
  'jquery.instructure_misc_helpers' /* replaceTags */,
  'jquery.instructure_misc_plugins' /* confirmDelete, showIf, .dim */,
  'jquery.keycodes' /* keycodes */,
  'jquery.loadingImg' /* loadingImage */,
  'jquery.templateData' /* fillTemplateData, getTemplateData */
], function(I18n, $, addBank) {
  var loadBanks = function() {
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
  };

  return loadBanks;
});
