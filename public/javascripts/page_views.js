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

define([
  'INST' /* INST */,
  'jquery' /* $ */,
  'jquery.ajaxJSON' /* ajaxJSON */
], function(INST, $) {

  $(document).ready(function(){
    var interactionSeconds = 0,
        $page_view_id = $("#page_view_id"),
        update_url = $("#page_view_update_path").attr('href'),
        eventInTime = false;
        
    INST.interaction_contexts = {};
    
    if(document.cookie && document.cookie.match(/last_page_view/)) {
      var match = document.cookie.match(/last_page_view=([^;]+)/);
      if(match && match[1]) {
        try {
          var data = $.parseJSON(unescape(match[1]));
          if(data && data.url && data.seconds) {
            setTimeout(function() {
              $.ajaxJSON(data.url, "PUT", {interaction_seconds: data.seconds}, function() {
              }, function() {}, 3000);
            });
          }
        } catch(e) {
        }
      }
      document.cookie = "last_page_view=;expires=Thu, 01-Jan-1970 00:00:01 GMT";
    }
    if($page_view_id.length > 0) {
      var secondsSinceLastEvent = 0;
      var intervalInSeconds = 60*5;
      $(document).bind('page_view_id_received', function(event, id) {
        $("#page_view_id").text(id);
        update_url = "/page_views/" + id;
      });
      var updateTrigger;
      $(document).bind('page_view_update', function(event, force) {
        var data = {};

        if(force || (interactionSeconds > 10 && secondsSinceLastEvent < intervalInSeconds)) {
          data.interaction_seconds = interactionSeconds;
          $.ajaxJSON(update_url, "PUT", data, function(resultData) {
            if(resultData && resultData.id) {
              $(document).triggerHandler('page_view_id_receved', resultData.id);
            }
          }, function(result, xhr) {
            if(xhr.status === 422) {
              clearInterval(updateTrigger);
            }
          });
          interactionSeconds = 0;
        }
      });
      updateTrigger = setInterval(function() {
        $(document).triggerHandler('page_view_update');
      }, 1000*intervalInSeconds);
      window.onbeforeunload = function() {
        if(interactionSeconds > 30) {
          var exdate=new Date();
          exdate.setDate(exdate.getDate()+1);
          var value = JSON.stringify({url: update_url, seconds: interactionSeconds});
          document.cookie="last_page_view=" +escape(value);
        }
      };

      var eventInTime = false;
      $(document).bind('mousemove keypress mousedown focus', function() {
        eventInTime = true;
      });
      setInterval(function() {
        if(eventInTime) {
          interactionSeconds++;
          if(INST && INST.interaction_context && INST.interaction_contexts) {
            INST.interaction_contexts[INST.interaction_context] = (INST.interaction_contexts[INST.interaction_context] || 0) + 1;
          }
          eventInTime = false;
          if(secondsSinceLastEvent >= intervalInSeconds) {
            secondsSinceLastEvent = 0;
            $(document).triggerHandler('page_view_update');
          }
          secondsSinceLastEvent = 0;
        } else {
          secondsSinceLastEvent++;          
        }
      }, 1000);
    }
  });
});

