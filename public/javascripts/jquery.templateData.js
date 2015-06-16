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
  'jquery' /* $ */,
  'str/htmlEscape',
  'jquery.instructure_misc_helpers' /* replaceTags */
], function($, htmlEscape) {

  // Fills the selected object(s) with data values as specified.  Plaintext values should be specified in the
  //  data: data used to fill template.
  //  id: set the id attribute of the template object
  //  textValues: a list of strings, which values should be plaintext
  //  htmlValues: a list of strings, which values should be html
  //  hrefValues: List of string.  Searches for all anchor tags in the template
  //    and globally replaces "{{ value }}" with data[value].  Useful for adding
  //    new elements asynchronously, when you don't know what their URL will be
  //    until they're created.
  $.fn.fillTemplateData = function(options) {
    if(this.length && options) {
      if (options.iterator) {
        //  todo: replace .andSelf with .addBack when JQuery is upgraded.
        this.find("*").andSelf().each(function(){
          var $el = $(this);
          $.each(["name", "id", "class"], function(i, attr){
            if ( $el.attr(attr) ) {
              $el.attr(attr, $el.attr(attr).replace(/-iterator-/, options.iterator));
            }
          });
        });
      }
      if(options.id) {
        this.attr('id', options.id);
      }
      var contentChange = false;
      if(options.data) {
        for(var item in options.data) {
          if(options.except && $.inArray(item, options.except) != -1) {
            continue;
          }
          if (options.data[item] && options.dataValues && $.inArray(item, options.dataValues) != -1) {
            this.data(item, options.data[item].toString());
          }
          var $found_all = this.find("." + item);
          var avoid = options.avoid || "";
          $found_all.each(function() {
            var $found = $(this);
            if($found.length > 0 && $found.closest(avoid).length === 0) {
              if(typeof(options.data[item]) == "undefined" || options.data[item] === null) {
                options.data[item] = "";
              }
              if(options.htmlValues && $.inArray(item, options.htmlValues) != -1) {
                $found.html($.raw(options.data[item].toString()));
                if($found.hasClass('user_content')) {
                  contentChange = true;
                  $found.removeClass('enhanced');
                  $found.data('unenhanced_content_html', options.data[item].toString());
                }
              } else if ($found[0].tagName.toUpperCase() == "INPUT") {
                $found.val(options.data[item]);
              } else {
                try {
                  var str = options.data[item].toString();
                  $found.html(htmlEscape(str));
                } catch(e) { }
              }
            }
          });
        }
      }
      if(options.hrefValues && options.data) {
        this.find("a,span[rel]").each(function() {
          var $obj = $(this), 
              oldHref, oldRel, oldName;
          for(var i in options.hrefValues) {
            if(!options.hrefValues.hasOwnProperty(i)) {
              continue;
            }
            var name = options.hrefValues[i];
            if(oldHref = $obj.attr('href')) {
              var newHref = $.replaceTags(oldHref, name, encodeURIComponent(options.data[name]));
              var orig = $obj.text() === $obj.html() ? $obj.text() : null;
              if(oldHref !== newHref) {
                $obj.attr('href', newHref);
                if(orig) {
                  $obj.text(orig);
                }
              }
            }
            if(oldRel = $obj.attr('rel')) {
              $obj.attr('rel', $.replaceTags(oldRel, name, options.data[name]));
            }
            if(oldName = $obj.attr('name')) {
              $obj.attr('name', $.replaceTags(oldName, name, options.data[name]));
            }
          }
        });
      }
      if(contentChange) {
        $(document).triggerHandler('user_content_change');
      }
    
    }
    return this;
  };

  $.fn.fillTemplateData.defaults = {htmlValues: null, hrefValues: null};

  // Reverse version of fillTemplateData.  Lets you pull out the string versions of values held in divs, spans, etc.
  // Based on the usage of class names within an object to specify an object's sub-parts.
  $.fn.getTemplateData = function(options) {
    if(!this.length || !options) {
      return {};
    }
    var result = {}, item, val;
    if(options.textValues) {
      var _this = this;
      options.textValues.forEach(function(item) {
        var $item = _this.find("." + item.replace(/\[/g, '\\[').replace(/\]/g, '\\]') + ":first");
        val = $.trim($item.text());
        if($item.html() === "&nbsp;") { val = ""; }
        if(val.length === 1 && val.charCodeAt(0) === 160) {
          val = "";
        }
        result[item] = val;
      });
    }
    if(options.dataValues) {
      for(item in options.dataValues) {
        var val = this.data(options.dataValues[item]);
        if(val) {
          result[options.dataValues[item]] = val;
        }
      }
    }
    if(options.htmlValues) {
      for(item in options.htmlValues) {
        var $elem = this.find("." + options.htmlValues[item].replace(/\[/g, '\\[').replace(/\]/g, '\\]') + ":first");
        val = null;
        if($elem.hasClass('user_content') && $elem.data('unenhanced_content_html')) {
          val = $elem.data('unenhanced_content_html');
        } else {
          val = $.trim($elem.html());
        }
        result[options.htmlValues[item]] = val;
      }
    }
    return result;
  };

  $.fn.getTemplateValue = function(value, options) {
    var opts = $.extend({}, options, {textValues: [value]});
    return this.getTemplateData(opts)[value];
  };

});
