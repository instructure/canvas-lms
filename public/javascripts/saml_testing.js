define([
  'jquery' /* $ */
], function($) {
  $(document).ready(function() {
    var $saml_debug_info = $('#saml_debug_info'),
        $start_saml_debugging = $('#start_saml_debugging'),
        $stop_saml_debugging = $('#stop_saml_debugging'),
        $refresh_saml_debugging = $('#refresh_saml_debugging'),
        refresh_timer = null;
    
    var stop_debugging = function(){
      clearTimeout(refresh_timer);
      $start_saml_debugging.show();
      $refresh_saml_debugging.hide();
      $stop_saml_debugging.hide();
      $saml_debug_info.html("");
      $saml_debug_info.hide();
    };
    
    var load_debug_data = function(new_debug_session){
      clearTimeout(refresh_timer);
      var url = $start_saml_debugging.attr('href');
      if(new_debug_session){
        url = url + "?start_debugging=true"
      }
      $.ajaxJSON(url, 'GET', {}, function (data) {
        if (data) {
          if (data.debugging) {
            $saml_debug_info.html($.raw(data.debug_data));
            $saml_debug_info.show();
            refresh_timer = setTimeout(function () {load_debug_data(false);}, 30000);
          } else {
            stop_debugging();
          }
        }
      });
    };

    $start_saml_debugging.click(function(event){
      event.preventDefault();
      load_debug_data(true);
      $start_saml_debugging.hide();
      $refresh_saml_debugging.show();
      $stop_saml_debugging.show();
    });

    $refresh_saml_debugging.click(function(event){
      event.preventDefault();
      load_debug_data(false);
    });
    
    $stop_saml_debugging.click(function(event){
      event.preventDefault();
      stop_debugging();
      
      var url = $stop_saml_debugging.attr('href');
      $.ajaxJSON(url, 'GET', {}, function (data) {
      });
    });
    
  });
});
