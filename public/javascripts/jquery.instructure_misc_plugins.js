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
  'i18n!instructure',
  'jquery' /* $ */,
  'str/htmlEscape',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jqueryui/dialog',
  'jquery.scrollToVisible' /* scrollToVisible */,
  'vendor/jquery.ba-hashchange' /* hashchange */,
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */
], function(I18n, $, htmlEscape) {

  $.fn.setOptions = function(prompt, options) {
    var result = prompt ? "<option value=''>" + htmlEscape(prompt) + "</option>" : "";

    if (options == null) {
      options = [];
    }

    options.forEach( function(opt) {
      escOpt = htmlEscape(opt);
      result += "<option value=\"" + escOpt + "\">" + escOpt + "</option>";
    });

    return this.html(result);
  }

  // this function is to prevent you from doing all kinds of expesive operations on a
  // jquery object that doesn't actually have any elements in it
  // it is similar and inspired by http://www.slideshare.net/paul.irish/perfcompression (slide #42)
  // to use it do something like:
  // $("a .bunch #of .nodes").ifExists(function(orignalQuery){
  //   //  'this' points to the original jquery object (in this case, $("a .bunch #of .nodes") );
  //   // orignalQuery is the same as 'this';
  //   this.slideUp().dialog().show();
  // });
  $.fn.ifExists = function(func){
    this.length && func.call(this, this);
    return this;
  };

  // Returns the width of the browser's scroll bars.
  $.fn.scrollbarWidth = function() {
      var $div = $('<div style="width:50px;height:50px;overflow:hidden;position:absolute;top:-200px;left:-200px;"><div style="height:100px;"></div>').appendTo(this),
          $innerDiv = $div.find('div');
      // Append our div, do our calculation and then remove it
      var w1 = $innerDiv.innerWidth();
      $div.css('overflow-y', 'scroll');
      var w2 = $innerDiv.innerWidth();
      $div.remove();
      return (w1 - w2);
  };

  // Simple animation for dimming an element's opacity
  $.fn.dim = function(speed) {
    return this.animate({opacity: 0.4}, speed);
  };

  $.fn.undim = function(speed) {
    return this.animate({opacity: 1.0}, speed);
  };


  // Helper for deleting objects from the DOM and db.
  //  url: URL to pass DELETE message.  If none provided,
  //    behaves as if the request were a success.  Useful for testing.
  //  message: Confirmation message
  //  cancelled: Function to handle cancel.
  //  confirmed: Function to handle confirm, before submit.
  //  success: What to do on success.  If none provided, fades
  //    out the element and removes it from the DOM.
  //  error: Error.
  //  dialog: If present, do a jquery.ui.dialog instead of a confirm(). If an
  //    object, it will be merged into the dialog options.
  $.fn.confirmDelete = function(options) {
    var options = $.extend({}, $.fn.confirmDelete.defaults, options);
    var $object = this;
    var $dialog = null;
    var result = true;
    options.noMessage = options.noMessage || options.no_message;
    var onContinue = function() {
      if (!result) {
        if (options.cancelled && $.isFunction(options.cancelled)) {
          options.cancelled.call($object);
        }
        return;
      }
      if (!options.confirmed) {
        options.confirmed = function() {
          $object.dim();
        };
      }
      options.confirmed.call($object);
      if (options.url) {
        if (!options.success) {
          options.success = function(data) {
            $object.fadeOut('slow', function() {
              $object.remove();
            });
          };
        }
        var data = options.prepareData ? options.prepareData.call($object, $dialog) : {};
        if (options.token) {
          data.authenticity_token = options.token;
        }
        if (!data.authenticity_token) {
          data.authenticity_token = $("#ajax_authenticity_token").text();
        }
        $.ajaxJSON(options.url, "DELETE", data, function(data) {
          options.success.call($object, data);
        }, function(data, request, status, error) {
          if (options.error && $.isFunction(options.error)) {
            options.error.call($object, data, request, status, error);
          } else {
            $.ajaxJSON.unhandledXHRs.push(request);
          }
        });
      } else {
        if (!options.success) {
          options.success = function() {
            $object.fadeOut('slow', function() {
              $object.remove();
            });
          };
        }
        options.success.call($object);
      }
    }
    if (options.message && !options.noMessage && !$.skipConfirmations) {
      if (options.dialog) {
        result = false;
        var dialog_options = typeof(options.dialog) == "object" ? options.dialog : {};
        $dialog = $(options.message).dialog($.extend({}, {
          modal: true,
          close: onContinue,
          buttons: [
            {
              text: I18n.t('#buttons.cancel', 'Cancel'),
              click: function() { $(this).dialog('close'); } // ; onContinue();
            }, {
              text: I18n.t('#buttons.delete', 'Delete'),
              'class': 'btn-primary',
              click: function() { result = true; $(this).dialog('close'); }
            }
          ]
        }, dialog_options));
        return;
      } else {
        result = confirm(options.message);
      }
    }
    onContinue();
  };
  $.fn.confirmDelete.defaults = {
    message: I18n.t('confirms.default_delete_thing', "Are you sure you want to delete this?")
  };

  // Watches the given element's location.href for any changes
  // to the fragment ("#...") and calls the provided function
  // when there are any.
  // $(document).fragmentChange(function(event, hash) { alert(hash); });
  $.fn.fragmentChange = function(fn) {
    if(fn && fn !== true) {
      var query = (window.location.search || "").replace(/^\?/, "").split("&");
      var idx;
      // The URL can hard-code a hash regardless of what's
      // actually shown in the hash by specifying a query
      // parameter, hash=some_hash
      var query_hash = null;
      for(idx in query) {
        var item = query[idx];
        if(item && item.indexOf("hash=") === 0) {
          query_hash = "#" + item.substring(5);
        }
      }
      this.bind('document_fragment_change', fn);
      var $doc = this;
      var found = false;
      // Can only be used on the root document,
      // will not work on an iframe, for example.
      for(idx in $._checkFragments.fragmentList) {
        var obj = $._checkFragments.fragmentList[idx];
        if(obj.doc[0] == $doc[0]) {
          found = true;
        }
      }
      if(!found) {
        $._checkFragments.fragmentList.push({
          doc: $doc,
          fragment: ""
        });
      }
      $(window).bind('hashchange', $._checkFragments);
      setTimeout(function() {
        if(query_hash && query_hash.length > 0) {
          $doc.triggerHandler('document_fragment_change', query_hash);
        } else if($doc && $doc[0] && $doc[0].location && $doc[0].location.hash.length > 0) {
          $doc.triggerHandler('document_fragment_change', $doc[0].location.hash);
        }
      }, 500);
    } else {
      this.triggerHandler('document_fragment_change', this[0].location.hash);
    }
    return this;
  };
  $._checkFragments = function() {
    var list = $._checkFragments.fragmentList;
    for(var idx in list) {
      var obj = list[idx];
      var $doc = obj.doc;
      if($doc[0].location.hash != obj.fragment) {
        $doc.triggerHandler('document_fragment_change', $doc[0].location.hash);
        obj.fragment = $doc[0].location.hash;
        $._checkFragments.fragmentList[idx] = obj;
      }
    }
  };
  $._checkFragments.fragmentList = [];
  // Triggers a click only if the anchor tag isn't disabled.
  $.fn.clickLink = function() {
    var $obj = this.eq(0);
    if(!$obj.hasClass('disabled_link')) {
      $obj.click();
    }
  };

  // jQuery supposedly has this built-in, but I haven't
  // had much success with it.
  $.fn.showIf = function(bool) {
    if ($.isFunction(bool)) {
      return this.each(function(index) {
        $(this).showIf(bool.call(this));
      });
    }
    if (bool) {
      this.show();
    } else {
      this.hide();
    }
    return this;
  };

  $.fn.disableIf = function(bool) {
    if ($.isFunction(bool)) { bool = bool.call(this); }
    this.prop('disabled', !!bool);
    return this;
  };

  $.fn.indicate = function(options) {
    options = options || {};
    var $indicator;
    if(options == "remove") {
      $indicator = this.data('indicator');
      if($indicator) {
        $indicator.remove();
      }
      return;
    }
    $(".indicator_box").remove();
    var offset = this.offset();
    if(options && options.offset) {
      offset = options.offset;
    }
    var width = this.width();
    var height = this.height();
    var zIndex = (options.container || this).zIndex();
    $indicator = $(document.createElement('div'));
    $indicator.css({
      width: width + 6,
      height: height + 6,
      top: offset.top - 3,
      left: offset.left - 3,
      zIndex: zIndex + 1,
      position: 'absolute',
      display: 'block',
      "-moz-border-radius": 5,
      opacity: 0.8,
      border: "2px solid #870",
      backgroundColor: "#fd0"
    });
    $indicator.addClass('indicator_box');
    $indicator.mouseover(function() {
      $(this).stop().fadeOut('fast', function() {
        $(this).remove();
      });
    });
    if(this.data('indicator')) {
      this.indicate('remove');
    }
    this.data('indicator', $indicator);
    $("body").append($indicator);
    if(options && options.singleFlash) {
      $indicator.hide().fadeIn().animate({opacity: 0.8}, 500).fadeOut('slow', function() {
        $(this).remove();
      });
    } else {
      $indicator.hide().fadeIn().animate({opacity: 0.8}, 500).fadeOut('slow').fadeIn('slow').animate({opacity: 0.8}, 2500).fadeOut('slow', function() {
        $(this).remove();
      });
    }
    if(options && options.scroll) {
      $("html,body").scrollToVisible($indicator);
    }
  };

  $.fn.hasScrollbar = function(){
    return this.length && (this[0].clientHeight < this[0].scrollHeight);
  };

  $.fn.log = function (msg) {
    console.log("%s: %o", msg, this);
    return this;
  };

  $.fn.chevronCrumbs = function(options) {
    return this.each(function() {
      $(this).show()
        .addClass("chevron-crumbs")
        .children().not("#hide-scratch")
          .addClass('chevron-crumb')
          .append('<span class="chevron-outer"><span class="chevron-inner"></span></span>')
          .filter(".active").prev().addClass("before-active");
    });
  };

  // this is used if you want to fill the browser window with something inside #content but you want to also leave the footer and header on the page.
  $.fn.fillWindowWithMe = function(options){
    var opts               = $.extend({minHeight: 400}, options),
        $this              = $(this),
        $wrapper_container = $('#wrapper-container'),
        $main              = $('#main'),
        $not_right_side    = $('#not_right_side'),
        $window            = $(window),
        $toResize          = $(this).add(opts.alsoResize);

    function fillWindowWithThisElement(){
      $toResize.height(0);
      var spaceLeftForThis = $window.height()
                             - ($wrapper_container.offset().top + $wrapper_container.outerHeight())
                             + ($main.height() - $not_right_side.height()),
          newHeight = Math.max(400, spaceLeftForThis);

      $toResize.height(newHeight);
      if ($.isFunction(opts.onResize)) {
        opts.onResize.call($this, newHeight);
      }
    }
    fillWindowWithThisElement();
    $window
      .unbind('resize.fillWindowWithMe')
      .bind('resize.fillWindowWithMe', fillWindowWithThisElement);
    return this;
  };

  $.fn.autoGrowInput = function(o) {

    o = $.extend({
        maxWidth: 1000,
        minWidth: 0,
        comfortZone: 70
    }, o);

    this.filter('input:text').each(function(){

      var minWidth = o.minWidth || $(this).width(),
        val = '',
        input = $(this),
        testSubject = $('<tester/>').css({
          position: 'absolute',
          top: -9999,
          left: -9999,
          width: 'auto',
          fontSize: input.css('fontSize'),
          fontFamily: input.css('fontFamily'),
          fontWeight: input.css('fontWeight'),
          letterSpacing: input.css('letterSpacing'),
          whiteSpace: 'nowrap'
        }),
        check = function() {

          setTimeout(function() {
            if (val === (val = input.val())) {return;}

            // Enter new content into testSubject
            var escaped = val.replace(/&/g, '&amp;').replace(/\s/g,'&nbsp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
            testSubject.html(escaped);

            // Calculate new width + whether to change
            var testerWidth = testSubject.width(),
              newWidth = (testerWidth + o.comfortZone) >= minWidth ? testerWidth + o.comfortZone : minWidth,
              currentWidth = input.width(),
              isValidWidthChange = (newWidth < currentWidth && newWidth >= minWidth)
                                   || (newWidth > minWidth && newWidth < o.maxWidth);

            // Animate width
            if (isValidWidthChange) {
              input.width(newWidth);
            }
          });

        };

      testSubject.insertAfter(input);

      $(this).bind('keyup keydown blur update change', check);

    });

    return this;

  };

  return $;
});

