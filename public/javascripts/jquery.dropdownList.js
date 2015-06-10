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
  'jquery' /* $ */
], function($) {

  /**
   * TL;DR: Remove this file when possible.
   *
   * Please note that this file is considered very legacy.  All instances of it
   * should be evaluated and replaced with the newer and far better looking
   * KyleMenu.  The only other place that I've seen it in used is the file
   * attendance.js which is on the chopping block at some point in the future.
   * Once that file has been axed, then this file should be able to be removed.
   */

  // Simple dropdown list.  Takes the list of attributes specified in "options" and displays them
  // in a menu anchored to the selected element.
  $.fn.dropdownList = function(options) {
    if (this.length) {
      var $div = $("#instructure_dropdown_list");
      if (options == "hide" || options == "remove" || $div.data('current_dropdown_initiator') == this[0]) {
        $div.remove().data('current_dropdown_initiator', null);
        return;
      }
      var options = $.extend({}, $.fn.dropdownList.defaults, options),
          $list = $div.children("div.list");
      if (!$list.length) {
        $div = $("<div id='instructure_dropdown_list'><div class='list ui-widget-content'></div></div>").appendTo("body");
        $(document).mousedown(function(event) {
          if ($div.data('current_dropdown_initiator') && !$(event.target).closest("#instructure_dropdown_list").length) {
            $div.hide().data('current_dropdown_initiator', null);
          }
        }).mouseup(function(event) {
          if ($div.data('current_dropdown_initiator') && !$(event.target).closest("#instructure_dropdown_list").length) {
            $div.hide();
            setTimeout(function() {
              $div.data('current_dropdown_initiator', null);
            }, 100);
          }
        }).add(this).add($div).keydown(function(event) {
          if ($div.data('current_dropdown_initiator')) {
            var $current = $div.find(".ui-state-hover,.ui-state-active");
            if (event.keyCode == 38) { // up
              if ($current.length && $current.prev().length) {
                $current.removeClass('ui-state-hover ui-state-active').addClass('minimal')
                  .prev().addClass('ui-state-hover').removeClass('minimal')
                  .find('span').focus();
              } else {
                $item.focus();
              }
              return false;
            } else if (event.keyCode == 40) { // down
              if (!$current.length) {
                $div.find(".option:first")
                  .addClass('ui-state-hover').removeClass('minimal')
                  .find('span').focus();
              } else if ($current.next().length) {
                $current.removeClass('ui-state-hover ui-state-active').addClass('minimal')
                  .next().addClass('ui-state-hover').removeClass('minimal')
                  .find('span').focus();
              }
              return false;
            } else if (event.keyCode == 13 && $current.length) {
              $current.click();
              return false;
            } else {
              $div.hide().data('current_dropdown_initiator', null);
            }
          }
        });
        $div.find(".option").removeClass('ui-state-hover ui-state-active').addClass('minimal');
        $div.click(function(event) {
          $div.hide().data('current_dropdown_initiator', null);
        });
        $list = $div.children("div.list");
      }
      $div.data('current_dropdown_initiator', this[0]);
      if (options.width) { 
        $div.width(options.width); 
      }
      if (options.height) { 
        $div.find(".list").css('maxHeight', options.height); 
      }
      $list.empty();
      $.each(options.options, function(optionHtml, callback){
        var $option = $("<div class='option minimal' style='cursor: pointer; padding: 2px 5px; overflow: hidden; white-space: nowrap;'>" +
                        "  <span tabindex='-1'>" + optionHtml + "</span>" +
                        "</div>").appendTo($list);

        if($.isFunction(callback)) {
          function unhoverOtherOptions(){
            $option.parent().find("div.option").removeClass('ui-state-hover ui-state-active').addClass('minimal');
          }
          $option.addClass('ui-state-default').bind({
            mouseenter: function() {
              unhoverOtherOptions();
              $option.addClass('ui-state-hover').removeClass('minimal');
            },
            mouseleave: unhoverOtherOptions,
            mousedown: function(event) {
              event.preventDefault();
              unhoverOtherOptions();
              $option.addClass('ui-state-active').removeClass('minimal');
            },
            mouseup: unhoverOtherOptions,
            click: callback
          });
        } else {
          $option.addClass('ui-state-disabled').bind({
            mousedown: function(event) {
              event.preventDefault();
            }
          });
        }
      });
      var offset = this.offset(),
          height = this.outerHeight(),
          width = this.outerWidth();
      
      $div.css({
        whiteSpace : "nowrap",
        position : 'absolute',
        top : offset.top + height, 
        left : offset.left + 5, 
        right : ''
      }).hide().show();
      
      //this is a fix so that if the dropdown ends up being off the page then move it back in so that it is on the page.
      if ($div.offset().left + $div.width() > $(window).width()) {
        $div.css({'left' : '','right' : 0});
      }
    }
    return this;
  };
  $.fn.dropdownList.defaults = {height: 250, width: "auto"};
  
});
