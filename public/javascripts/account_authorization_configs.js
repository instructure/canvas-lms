define([
  'i18n!account_authorization_configs',
  'jquery' /* $ */,
  'jquery.instructure_forms' /* formSubmit */,
  'jquery.keycodes' /* keycodes */,
  'jquery.loadingImg' /* loadingImage */
], function(I18n, $) {

  var new_type = null;
  
  $(".edit_auth_link").click(function(event) {
    event.preventDefault();
    $("#auth_form").addClass('editing').find(":text:first").focus().select();
  });
  
  $("#add_auth_select").change(function(event) {
      event.preventDefault();
      $("#auth_form").find(".cancel_button:first").click();
      new_type = $(this).find(":selected").val();
      $(".active").each(function(i){$(this).removeClass('active');})
      if(new_type == "" || new_type == null){
          new_type = null;
      }
      else{
          $("#" + new_type + "_div").addClass('active');
          $("#" + new_type + "_form").attr('id', 'auth_form');
          $("#no_auth").css('display', 'none');
          $("#auth_form").addClass('editing').find(":text:first").focus().select();
      }
  });
  
  $(".auth_type").each(function(i){
      $(this).find(".cancel_button").click(function() {
        $("#auth_form").removeClass('editing');
          if ( $('#no_auth').length && new_type ){
              $("#no_auth").css('display', 'inline');
              $("#" + new_type + "_div").removeClass('active');
              $("#auth_form").attr('id', new_type + '_form');
              new_type = null;
          }
      }).end().find(":text").keycodes('esc', function() {
        $(this).parents("#auth_form").find(".cancel_button:first").click();
      });
      
      $(this).formSubmit({
        beforeSubmit: function() {
         $(this).loadingImage();
        },
        success: function(data) {
          window.location.reload();
        }
      });
  });

  $("#discovery_url_form").formSubmit({
    success: function(data) {
      window.location.reload();
    }
  });

  $('#discovery_url_config .delete_url').click(function(){
    $.ajaxJSON( $(this).data('url'), "DELETE", {}, function(){
      $('#discovery_url_input').val("");
      $('#discovery_url_display').text(I18n.t('no_discovery_url', "None set"));
    });
  });

  $(".add_secondary_ldap_link").click(function(event) {
    event.preventDefault();
    $(".ldap_secondary").show();
    $("#secondary_ldap_config_disabled").val("0");
    $(this).hide();
  });
  
  $(".remove_secondary_ldap_link").click(function(event) {
    event.preventDefault();
    $(".ldap_secondary").hide();
    $("#secondary_ldap_config_disabled").val("1");
    $(".add_secondary_ldap_link").show();
  });
});  
