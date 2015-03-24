define([
  'jquery',
  'old_unsupported_dont_use_react',
  '../jsx/sfu_copyright_compliance_notice/SFUCopyrightComplianceNoticeModalDialog'
], function($, React, SFUCopyrightComplianceModalDialog) {

    var render = function(formId) {
        React.renderComponent(SFUCopyrightComplianceModalDialog({
            modalIsOpen: true,
            formId: formId
        }), document.getElementById('wizard_box'));
    };

    var attachClickHandler = function(formId) {
        var $button = $('#' + formId + ' button.btn-publish');
        $button.on('click', function(ev) {
            ev.preventDefault();
            render(formId);
        });
        $button.attr('disabled', false);
    };

    return {
        attachClickHandlerTo: attachClickHandler
    };
});