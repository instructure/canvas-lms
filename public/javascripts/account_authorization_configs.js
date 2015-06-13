define([
  'jquery' /* $ */,
  'jquery.instructure_forms' /* formSubmit */,
  'jquery.keycodes' /* keycodes */,
  'jquery.loadingImg' /* loadingImage */
], function($) {

  $("#add_auth_select").change(function(event) {
    event.preventDefault();
    var new_type = $(this).find(":selected").val();
    if(new_type != "" || new_type != null){
      $(".new_auth").hide();
      $form = $("#" + new_type + "_form");
      $form.show();
      $form.find(":text:first").focus();
      $("#no_auth").css('display', 'none');
    }
  });

});
