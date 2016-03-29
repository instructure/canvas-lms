define([
  'jquery' // $
], function($) {

  $(document).ready(function() {
    $("#oauth2_accept_form").submit(function(){
      var $btn = $(this).find(".btn-primary");
      $btn.attr('value', $btn.data('disable-with'));
      $btn.attr('disabled', true);
    });
  });

});
