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

//create a global object "INST" that we will have be Instructure's namespace.
if (typeof(window.INST) == "undefined") {
  window.INST = {}; //this is our "namespace"
}

I18n.scoped('instructure', function(I18n) {
  // ============================================================================================
  // = Try to figure out what browser they are using and set INST.broswer.theirbrowser to true  =
  // = and add a css class to the body for that browser                                       =
  // ============================================================================================
  
  INST.browser = {};
  $.each([7,8,9], function() {
    if ($('html').hasClass('ie'+this)) {
      INST.browser['ie'+this] = INST.browser.ie = true;
    }  
  });
  if (window.devicePixelRatio) {
    INST.browser.webkit = true;
    //from: http://www.byond.com/members/?command=view_post&post=53727
    INST.browser[(escape(navigator.javaEnabled.toString()) == 'function%20javaEnabled%28%29%20%7B%20%5Bnative%20code%5D%20%7D') ? 'chrome' : 'safari'] = true;
  }
  //this is just using jquery's browser sniffing result of if its firefox, it should probably use feature detection
  INST.browser.ff = $.browser.mozilla;
  // now we have some degree of knowing which of the common browsers it is, on dom ready, give the body those classes
  // so for example, if you were on IE6 the body would have the classes "ie" AND "ie6"
  $(function(){
    $.each(INST.browser, function(k,v){
      if (v) {
        $('body').addClass(k);
      }
    });
  });


  // add ability to handle css3 opacity transitions on show or hide
  // if you want to use this just add the class 'use-css-transitions-for-show-hide' to an element.
  // whenever that element is .show()n or .hide()n it will use a css opacity transition (in non-IE browsers). 
  // if you want to override the length or details of the transition, just specify it in a css file.
  // purposely only supporting ff, webkit & opera because they are the only ones that fire the transitionEnd event, add others when supported
  if ($.detect(["WebkitTransitionProperty", "MozTransitionProperty", "OTransitionProperty"], function(){ return document.body.style[this] !== undefined })) {
    $(function(){ //have to do it later (on dom ready) because jQuery UI is going to override show and hide as well
      $.each(['show', 'hide', 'remove'], function(i, showHideOrRemove) {
        var previousFn = $.fn[showHideOrRemove];
        $.fn[showHideOrRemove] = function(){
          if (!arguments.length) {
            return this.each(function() {
              var $this = $(this);
              // if you can't add the class .use-css-transitions-for-show-hide to your element, you can
              // add it to this selector to have it use css3 transitions.
              if ($this.is('.use-css-transitions-for-show-hide, .ui-widget-overlay')) {
                var oldOpacityCssAttribute = this.style.opacity,
                    oldComputedOpacity = $this.css('opacity'),
                    newOpacity = (showHideOrRemove === 'hide' || showHideOrRemove === 'remove') ? 0 : (!oldComputedOpacity || oldComputedOpacity == "0" ? 1 : oldComputedOpacity);
                if (showHideOrRemove === 'show' && $this.is(':hidden')) {
                  this.style.opacity = 0;
                  previousFn.apply($this); //change out of display:none
                }
                
                // things like '.ui-widget-overlay' may not already have this class,
                // it is needed in the css to tell the browser to use the animation.
                $this.addClass('use-css-transitions-for-show-hide');
                $this.bind('transitionend oTransitionEnd webkitTransitionEnd', function(event){
                  if (event.originalEvent.propertyName === 'opacity') {
                    previousFn.apply($(this)); //change to display:none when we are hiding.
                    this.style.opacity = oldOpacityCssAttribute;
                    $(this).unbind(event);
                  }
                });
                setTimeout(function(){
                  $this.css('opacity', newOpacity);
                }, 1);
              } else {
                previousFn.apply($this);
              }
            });
          } else {
            return previousFn.apply(this, arguments);
          }
        };
      });
    });
  }

  function getTld(hostname){
    hostname = (hostname || "").split(":")[0];
    var parts = hostname.split("."),
        length = parts.length;
    return ( length > 1  ? 
      [ parts[length - 2] , parts[length - 1] ] : 
      parts 
    ).join("");
  }
  var locationTld = getTld(window.location.hostname);
  $.expr[':'].external = function(element){
    var href = $(element).attr('href');
    //if a browser doesnt support <a>.hostname then just dont mark anything as external, better to not get false positives.
    return !!(href && href.length && !href.match(/^(mailto\:|javascript\:)/) && element.hostname && getTld(element.hostname) != locationTld);
  };
    
  window.equella = {
    ready: function(data) {
      $(document).triggerHandler('equella_ready', data);
    },
    cancel: function() {
      $(document).triggerHandler('equella_cancel');
    }
  };
  $(document).bind('equella_ready', function(event, data) {
    $("#equella_dialog").triggerHandler('equella_ready', data);
  }).bind('equella_cancel', function() {
    $("#equella_dialog").dialog('close');
  });
  
  window.jsonFlickrApi = function(data) {
    $("#instructure_image_search").triggerHandler('search_results', data);
  };


});

