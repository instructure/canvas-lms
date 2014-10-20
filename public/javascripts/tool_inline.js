/**
 * Copyright (C) 2011 Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
define(['jquery', 'jquery.google-analytics'], function($) {

var $toolForm = $("#tool_form")

var launchToolManually = function(){
  var $button = $toolForm.find('button');

  $toolForm.show();

  // Firefox remembers disabled state after page reloads
  $button.attr('disabled', false);
  setTimeout(function() {
    // LTI links have a time component in the signature and will
    // expire after a few minutes.
    $button.attr('disabled', true).text($button.data('expired_message'));
  }, 60 * 2.5 * 1000);


  $toolForm.submit(function() {
    $(this).find(".load_tab,.tab_loaded").toggle();
  });
}

var launchToolInNewTab = function(){
  $toolForm.attr('target', '_blank');
  launchToolManually();
}

switch($toolForm.data('tool-launch-type')){
  case 'window':
    $toolForm.show();
    launchToolInNewTab();
    break;
  case 'self':
    $toolForm.removeAttr('target')
    try {
      $toolForm.submit();
    } catch(e){}
    break;
  default:
    //Firefox throws an error when submitting insecure content
    try {
      $toolForm.submit();
    } catch(e){}

    $("#tool_content").bind("load", function(){
      $("#content").addClass('padless');
      $('#insecure_content_msg').hide();
      $toolForm.hide();
    });
    setTimeout(function(){
      if($('#insecure_content_msg').is(":visible")){
        $('#load_failure').show()
        launchToolInNewTab();
      }
    }, 3 * 1000);
    break;
}

//Google analytics tracking code
var toolName = $toolForm.data('tool-id') || "unknown";
var toolPath = $toolForm.data('tool-path');
var messageType = $toolForm.data('message-type') || 'tool_launch';
$.trackEvent(messageType, toolName, toolPath);

// iframe sizing
window.addEventListener('message', function(e) {
  try {
    var message = JSON.parse(e.data);
    if (message.subject === 'lti.frameResize') {
      var height = message.height;
      if (height >= 5000) height = 5000;
      if (height <= 0) height = 1;

      $('.tool_content_wrapper').height(height).data('height_overridden', true);
    }
  } catch(err) {
    (console.error || console.log)('invalid message received from ', e.origin);
  }
});

$(function() {
  var $tool_content_wrapper = $('.tool_content_wrapper');
  if (!$tool_content_wrapper.data('height_overridden')) {
    $tool_content_wrapper.height($('#main').height());
  }
});

});
