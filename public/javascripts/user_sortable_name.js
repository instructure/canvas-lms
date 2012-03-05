define([
  'jquery' /* jQuery, $ */,
  'user_utils' /* userUtils */
], function($, userUtils) {

$(function () {
  var $short_name = $('input[name="user[short_name]"]')
  // Sometimes user[name] is used for search forms on the same page as edit forms;
  // so find the name by starting with the short_name
  var $name = $short_name.parents('form').find('input[name="user[name]"]');
  var $sortable_name = $('input[name="user[sortable_name]"]');
  var prior_name = $name.attr('value');
  $name.keyup(function() {
    var name = $name.attr('value');
    var sortable_name = $sortable_name.attr('value');
    var sortable_name_parts = userUtils.nameParts(sortable_name);
    if (jQuery.trim(sortable_name) === '' || userUtils.firstNameFirst(sortable_name_parts) === jQuery.trim(prior_name)) {
      var parts = userUtils.nameParts(name, sortable_name_parts[1]);
      $sortable_name.attr('value', userUtils.lastNameFirst(parts));
    }
    var short_name = $short_name.attr('value');
    if (jQuery.trim(short_name) === '' || short_name === prior_name) {
      $short_name.attr('value', name);
    }
    prior_name = $(this).attr('value');
  });
});
});

