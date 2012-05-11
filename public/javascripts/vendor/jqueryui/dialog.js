define(['jquery', 'jqueryui/dialog-unpatched'], function($) {
  
  // have UI dialogs default to modal:true
  $.widget('instructure.dialog', $.ui.dialog, { options: {modal: true} });
  return $;

});
