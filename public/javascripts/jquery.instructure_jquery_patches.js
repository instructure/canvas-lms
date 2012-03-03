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
  'jquery' /* jQuery, $ */,
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */,
  'jqueryui/dialog'
], function($) {

  // have UI dialogs default to modal:true
  $.widget('instructure.dialog', $.ui.dialog, { options: {modal: true} });

  // This is so that if you disable an element, that it also gives it the class disabled.  
  // that way you can add css classes for our friend IE6. so rather than using selector:disabled, 
  // you can do selector.disabled.
  // works on both $(elem).attr('disabled', ...) AND $(elem).prop('disabled', ...)
  $.each([ "prop", "attr" ], function(i, propOrAttr ) {
    // set the `disabled.set` hook like this so we don't override any existing `get` hook
    $[propOrAttr+'Hooks'].disabled = $.extend( $[propOrAttr+'Hooks'].disabled, {
      set: function( elem, value, name ) {
        $(elem).toggleClass('disabled', !!value);
  
        // have to replicate wat jQuery's boolHook does because once you define your own hook
        // for an attribute/property it wont fall back to boolHook. and it is not exposed externally.
        elem[value ? 'setAttribute' : 'removeAttribute' ]('disabled', 'disabled');
        if ( 'disabled' in elem ) {
          // Only set the IDL specifically if it already exists on the element
          // ie for an <input> but not a <div> 
          elem.disabled = !!value;
        }
        return value;
      }
    });
  });

  // monkey patch jquery's JSON parsing so we can have all of our ajax responses return with
  // 'while(1);' prepended to them to protect against a CSRF attack vector.
  var _parseJSON = $.parseJSON;
  $.parseJSON = function() {
    "use strict";
    if (arguments[0]) {
      try {
        var newData = arguments[0].replace(/^while\(1\);/, '');
        arguments[0] = newData;
      } catch (err) {
        // data was not a string or something, just pass along to the real parseJSON
        // and let it handle errors.
      }
    }
    return _parseJSON.apply($, arguments);
  };
  $.ajaxSettings.converters["text json"] = $.parseJSON;

  // this is a patch so you can set the "method" atribute on rails' REST-ful forms.
  $.attrHooks.method = $.extend($.attrHooks.method, {
    set: function( elem, value ) {
      var orginalVal = value;
      value = value.toUpperCase() === 'GET' ? 'GET' : 'POST';
      if ( value === 'POST' ) {
        var $input = $(elem).find("input[name='_method']");
        if ( !$input.length ) {
          $input = $("<input type='hidden' name='_method'/>").prependTo(elem);
        }
        $input.val(orginalVal);
      }
      elem.setAttribute('method', value);
      return value;
    }
  });

  $.fn.originalScrollTop = $.fn.scrollTop;
  $.fn.scrollTop = function() {
    if(this.selector == "html,body" && arguments.length === 0) {
      console.error("$('html,body').scrollTop() is not cross-browser compatible... use $.windowScrollTop() instead");
    }
    return $.fn.originalScrollTop.apply(this, arguments);
  };
  $.windowScrollTop = function() {
    return ($.browser.safari ? $("body") : $("html")).scrollTop();
  };


});
