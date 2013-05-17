require([
  'i18n!assignments' /* I18n.t */,
  'jquery' /* $ */,
  'jquery.instructure_forms' /* formSubmit, formErrors */,
  'jqueryui/dialog',
  'jquery.instructure_misc_plugins' /* showIf */
  ], function(I18n, $) {
  window.attachAddAssignmentGroup = function($select, url) {
    var $group = $select;
    url = url || $("#add_assignment_type_form").attr('action');
    $group.change(function(event) {
      if($(this).val() == "new") {
        $("#add_assignment_type").show().dialog({
          title: I18n.t('titles.add_assignment_group', "Add Assignment Group"),
          width: 300,
          height: "auto",
          autoSize: true,
          modal: true,
          autoOpen: false,
          overlay: {
            backgroundColor: "#000",
            opacity: 0.5
          },
          open: function() {
            $("#add_assignment_type_form :text:first").focus().select();
            $("#add_assignment_type_form").find(".weight_assignment_groups").showIf($group.hasClass('weight'));
            $("#add_assignment_type_form").data('group_select', $group)
            .attr('action', url);
          },
          close: function() {
            if($group.val() == "new") {
              $group[0].selectedIndex = 0;
            }
          }
        }).dialog('open');
      }
    });
    if($group.val() == "new") {
      $group[0].selectedIndex = 0;
    }
  }
  $(document).ready(function() {
    $("#add_assignment_type_form").formSubmit({
      beforeSubmit: function(data) {
        $(this).find("button").attr('disabled', true).filter(".add_button").text(I18n.t('messages.adding_group', "Adding Group..."));
      },
      success: function(data) {
        $(this).find("button").attr('disabled', false).filter(".add_button").text(I18n.t('buttons.add_group', "Add Group"));
        var group = data.assignment_group;
        var $group = $("#add_assignment_type_form").data('group_select');
        var $option = $(document.createElement('option'));
        $option.val(group.id).text(group.name);
        $group.children("option:last").before($option);
        $group.val(group.id);
        $("#add_assignment_type").dialog('close');
      },
      error: function(data) {
        $(this).formErrors(data);
        $(this).find("button").attr('disabled', false).filter(".add_button").text(I18n.t('errors.add_group_failed', "Add Group Failed"));
      }
    });
    $("#add_assignment_type .cancel_button").click(function(event) {
      $("#add_assignment_type").dialog('close');
    });
  });
});
