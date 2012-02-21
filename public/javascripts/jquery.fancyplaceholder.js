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

// markup required:
// <span class=" field-with-fancyplaceholder"><label for="email">Email Address</span></label><input type="text" id="login_apple_id"></span>
//
// css required:
// span.field-with-fancyplaceholder{display:block;display:inline-block;position:relative;vertical-align:top;}
// span.field-with-fancyplaceholder label.placeholder{color:#999;cursor:text;pointer-events:none;}
// span.field-with-fancyplaceholder label.placeholder span{position:absolute;z-index:2;-webkit-user-select:none;padding:3px 6px;}
// span.field-with-fancyplaceholder label.focus{color:#ccc;}
// span.field-with-fancyplaceholder label.hidden{color:#fff;}
// span.field-with-fancyplaceholder input.invalid{background:#ffffc5;color:#F30;}
// span.field-with-fancyplaceholder input.editing{color:#000;background:none repeat scroll 0 0 transparent;overflow:hidden;}
//
// then: $(".field-with-fancyplaceholder input").fancyPlaceholder();

define(['jquery'], function($) {
	$.fn.fancyPlaceholder = function() {
	  var pollingInterval,
	  	  foundInputsAndLables = [];

    function hideOrShowLabels(){
      $.each(foundInputsAndLables, function(i, inputAndLable){
        inputAndLable[1][inputAndLable[0].val() ? 'hide' : 'show']();
      });
    }

	  return this.each(function() {
	    var $input = $(this),
	        $label = $("label[for="+$input.attr('id')+"]");

	    $label.addClass('placeholder').wrapInner("<span/>").css({
	      'font-family'   : $input.css('font-family'),
        'font-size'     : $input.css('font-size')
	    });

	    $input
        .focus(function(){
          $label.addClass('focus', 300);
        })
        .blur(function(){
          $label.removeClass('focus', 300);
        })
        .bind('keyup', hideOrShowLabels);

      // if this was already focused before we got here, make it light gray now. sorry, ie7 cant do :focus selector, it doesn't get this.
      try {
        if ($("input:focus").get(0) == this) {
          $input.triggerHandler('focus');
        }
      } catch(e) {}


      foundInputsAndLables.push([$input, $label]);

      if (!pollingInterval) {
        window.setInterval(hideOrShowLabels, 100);
      }
 	  });
	};
});
