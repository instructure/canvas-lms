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
  'i18n!instructure',
  'jquery' /* $ */,
  'underscore',
  'str/htmlEscape',
  'compiled/str/TextHelper',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_forms',
  'jqueryui/dialog',
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */
], function(INST, I18n, $, _, htmlEscape, TextHelper) {

  // Return the first value which passes a truth test
  $.detect = function(collection, callback) {
    var result;
    $.each(collection, function(index, value) {
      if (callback.call(value, value, index, collection)) {
        result = value;
        return false; // we found it, break the $.each() loop iteration by returning false
      }
    });
    return result;
  };

  $.encodeToHex = function(str) {
    var hex = "";
    var e = str.length;
    var c = 0;
    var h;
    for (var i = 0; i < str.length; i++) {
      part = str.charCodeAt(i).toString(16);
      while (part.length < 2) {
        part = "0" + part;
      }
      hex += part;
    }
    return hex;
  };
  $.decodeFromHex = function(str) {
    var r='';
    var i = 0;
    while(i < str.length){
      r += unescape('%'+str.substring(i,i+2));
      i += 2;
    }
    return r;
  };

  // useful for i18n, e.g. t('key', 'pick one: %{select}', {select: $.raw('<select><option>...')})
  // note that raw returns a String object, so you may want to call toString
  // if you're using it elsewhere
  $.raw = function(str) {
    str = new String(str);
    str._icHTMLSafe = true;
    return str;
  }

  $.replaceOneTag = function(text, name, value) {
    if(!text) { return text; }
    name = (name || "").toString();
    value = (value || "").toString().replace(/\s/g, "+");
    var itemExpression = new RegExp("(%7B|{){2}[\\s|%20|\+]*" + name + "[\\s|%20|\+]*(%7D|}){2}", 'g');
    return text.replace(itemExpression, value);
  };
  // backwards compatible with only one tag
  $.replaceTags = function(text, mapping_or_name, maybe_value) {
    if (typeof mapping_or_name == 'object') {
      for (var name in mapping_or_name) {
        text = $.replaceOneTag(text, name, mapping_or_name[name])
      }
      return text;
    } else {
      return $.replaceOneTag(text, mapping_or_name, maybe_value)
    }
  }

  var scrollSideBarIsBound = false;
  $.scrollSidebar = function(){
    if(!scrollSideBarIsBound){
      var $right_side = $("#right-side"),
          $main = $('#main'),
          $not_right_side = $("#not_right_side"),
          $window = $(window),
          $rightSideWrapper = $("#right-side-wrapper"),
          headerHeight = $right_side.offset().top,
          rightSideMarginBottom = $rightSideWrapper.height() - $right_side.outerHeight(),
          rightSideMarginTop = $right_side.offset().top - $rightSideWrapper.offset().top;

      function onScroll(){
        var windowScrollTop = $window.scrollTop(),
            windowScrollIsBelowHeader = (windowScrollTop > headerHeight - rightSideMarginTop);

        if (windowScrollIsBelowHeader) {
          var notRightSideHeight = $not_right_side.height(),
              rightSideHeight = $right_side.height(),
              notRightSideIsTallerThanRightSide = notRightSideHeight > rightSideHeight,
              rightSideBottomIsBelowMainBottom = ( headerHeight + $main.height() - windowScrollTop ) <= ( rightSideHeight + rightSideMarginBottom );
        }

        // windows chrome repaints when you set the class, even if the classes
        // aren't truly changing, which wreaks havoc on open select elements.
        // so we only toggle if we really need to
        if ((windowScrollIsBelowHeader && notRightSideIsTallerThanRightSide && !rightSideBottomIsBelowMainBottom) ^ $rightSideWrapper.hasClass('with-scrolling-right-side')) {
          $rightSideWrapper.toggleClass('with-scrolling-right-side');
        }
        if ((windowScrollIsBelowHeader && notRightSideIsTallerThanRightSide && rightSideBottomIsBelowMainBottom) ^ $rightSideWrapper.hasClass('with-sidebar-pinned-to-bottom')) {
          $rightSideWrapper.toggleClass('with-sidebar-pinned-to-bottom');
        }
      }
      var throttledOnScroll = _.throttle(onScroll, 50);
      throttledOnScroll();
      $window.scroll(throttledOnScroll);
      scrollSideBarIsBound = true;
    }
  };

  $.underscore = function(string) {
    return (string || "").replace(/([A-Z])/g, "_$1").replace(/^_/, "").toLowerCase();
  };

  $.titleize = function(string) {
    var res = (string || "").replace(/([A-Z])/g, " $1").replace(/_/g, " ").replace(/\s+/, " ").replace(/^\s/, "");
    return $.map(res.split(/\s/), function(word) { return (word[0] || "").toUpperCase() + word.substring(1); }).join(" ");
  };

  $.parseUserAgentString = function(userAgent) {
    userAgent = (userAgent || "").toLowerCase();
    var data = {
      version: (userAgent.match( /.+(?:me|ox|it|ra|ie|er|rv|version)[\/: ]([\d.]+)/ ) || [0,null])[1],
      chrome: /chrome/.test( userAgent ),
      safari: /webkit/.test( userAgent ),
      opera: /opera/.test( userAgent ),
      msie: (/msie/.test( userAgent ) || /trident/.test( userAgent )) && !(/opera/.test( userAgent )),
      firefox: /firefox/.test( userAgent),
      mozilla: /mozilla/.test( userAgent ) && !(/(compatible|webkit)/.test( userAgent )),
      speedgrader: /speedgrader/.test( userAgent )
    };
    var browser = null;
    if(data.chrome) {
      browser = "Chrome";
    } else if(data.safari) {
      browser = "Safari";
    } else if(data.opera) {
      browser = "Opera";
    } else if(data.msie) {
      browser = "Internet Explorer";
    } else if(data.firefox) {
      browser = "Firefox";
    } else if(data.mozilla) {
      browser = "Mozilla";
    } else if(data.speedgrader) {
      browser = "SpeedGrader for iPad";
    }
    if (!browser) {
      browser = I18n.t('browsers.unrecognized', "Unrecognized Browser");
    } else if(data.version) {
      data.version = data.version.split(/\./).slice(0,2).join(".");
      browser = browser + " " + data.version;
    }
    return browser;
  };

  $.fileSize = function(bytes) {
    var factor = 1024;
    if(bytes < factor) {
      return parseInt(bytes, 10) + " bytes";
    } else if(bytes < factor * factor) {
      return parseInt(bytes / factor, 10) + "KB";
    } else {
      return (Math.round(10.0 * bytes / factor / factor) / 10.0) + "MB";
    }
  };

  $.getUserServices = function(service_types, success, error) {
    if(!$.isArray(service_types)) { service_types = [service_types]; }
    var url = "/services?service_types=" + service_types.join(",");
    $.ajaxJSON(url, 'GET', {}, function(data) {
      if(success) { success(data); }
    }, function(data) {
      if(error) { error(data); }
    });
  };

  var lastLookup; //used to keep track of diigo requests
  $.findLinkForService = function(service_type, callback) {
    var $dialog = $("#instructure_bookmark_search");
    if( !$dialog.length ) {
      $dialog = $("<div id='instructure_bookmark_search'/>");
      $dialog.append("<form id='bookmark_search_form' style='margin-bottom: 5px;'>" +
                       "<img src='/images/blank.png'/>&nbsp;&nbsp;" +
                       "<input type='text' class='query' style='width: 230px;'/>" +
                       "<button class='btn search_button' type='submit'>" +
                       htmlEscape(I18n.t('buttons.search', "Search")) + "</button></form>");
      $dialog.append("<div class='results' style='max-height: 200px; overflow: auto;'/>");
      $dialog.find("form").submit(function(event) {
        event.preventDefault();
        event.stopPropagation();
        var now = new Date();
        if(service_type == 'diigo' && lastLookup && now - lastLookup < 15000) {
          // let the user know we have to take things slow because of Diigo
          setTimeout(function() {
            $dialog.find("form").submit();
          }, 15000 - (now - lastLookup));
          $dialog.find(".results").empty()
            .append(htmlEscape(I18n.t('status.diigo_search_throttling', "Diigo limits users to one search every ten seconds.  Please wait...")));
          return;
        }
        $dialog.find(".results").empty().append(htmlEscape(I18n.t('status.searching', "Searching...")));
        lastLookup = new Date();
        var query = $dialog.find(".query").val();
        var url = $.replaceTags($dialog.data('reference_url'), 'query', query);
        $.ajaxJSON(url, 'GET', {}, function(data) {
          $dialog.find(".results").empty();
          if( !data.length ) {
            $dialog.find(".results").append(htmlEscape(I18n.t('no_results_found', "No Results Found")));
          }
          for(var idx in data) {
            data[idx].short_title = data[idx].title;
            if(data[idx].title == data[idx].description) {
              data[idx].short_title = TextHelper.truncateText(data[idx].description, {max: 30});
            }
            $("<div class='bookmark'/>")
              .appendTo($dialog.find(".results"))
              .append($('<a class="bookmark_link" style="font-weight: bold;"/>').attr({
                  href: data[idx].url,
                  title: data[idx].title
                }).text(data[idx].short_title)
              )
              .append($("<div style='margin: 5px 10px; font-size: 0.8em;'/>").text(data[idx].description || I18n.t('no_description', "No description")));
          }
        }, function() {
          $dialog.find(".results").empty()
            .append(htmlEscape(I18n.t('errors.search_failed', "Search failed, please try again.")));
        });
      });
      $dialog.delegate('.bookmark_link', 'click', function(event) {
        event.preventDefault();
        var url = $(this).attr('href');
        var title = $(this).attr('title') || $(this).text();
        $dialog.dialog('close');
        callback({
          url: url,
          title: title
        });
      });
    }
    $dialog.find(".search_button").text(service_type == 'delicious' ? I18n.t('buttons.search_by_tag', "Search by Tag") : I18n.t('buttons.search', "Search"));
    $dialog.find("form img").attr('src', '/images/' + service_type + '_small_icon.png');
    var url = "/search/bookmarks?q=%7B%7B+query+%7D%7D&service_type=%7B%7B+service_type+%7D%7D";
    url = $.replaceTags(url, 'service_type', service_type);
    $dialog.data('reference_url', url);
    $dialog.find(".results").empty().end()
      .find(".query").val("");
    $dialog.dialog({
      title: I18n.t('titles.bookmark_search', "Bookmark Search: %{service_name}", {service_name: $.titleize(service_type)}),
      open: function() {
        $dialog.find("input:visible:first").focus().select();
      },
      width: 400
    });
  };

  $.findImageForService = function(service_type, callback) {
    var $dialog = $("#instructure_image_search");
    $dialog.find("button").attr('disabled', false);
    if( !$dialog.length ) {
      $dialog = $("<div id='instructure_image_search'/>")
                  .append("<form id='image_search_form' class='form-inline' style='margin-bottom: 5px;'>" +
                            "<img src='/images/flickr_creative_commons_small_icon.png'/>&nbsp;&nbsp;" + 
                            "<input type='text' class='query' style='width: 250px;' placeholder='" +
                            htmlEscape(I18n.t('tooltips.enter_search_terms', "enter search terms")) + "'/>" + 
                            "<button class='btn' type='submit'>" +
                            htmlEscape(I18n.t('buttons.search', "Search")) + "</button></form>")
                  .append("<div class='results' style='max-height: 240px; overflow: auto;'/>");

      $dialog.find("form").submit(function(event) {
        event.preventDefault();
        event.stopPropagation();
        var now = new Date();
        $dialog.find("button").attr('disabled', true);
        $dialog.find(".results").empty().append(I18n.t('status.searching', "Searching..."));
        $dialog.bind('search_results', function(event, data) {
          $dialog.find("button").attr('disabled', false);
          if(data && data.photos && data.photos.photo) {
            $dialog.find(".results").empty();
            for(var idx in data.photos.photo) {
              var photo = data.photos.photo[idx],
                  image_url = "https://farm" + photo.farm + ".static.flickr.com/" + photo.server + "/" + photo.id + "_" + photo.secret + "_s.jpg",
                  big_image_url = "https://farm" + photo.farm + ".static.flickr.com/" + photo.server + "/" + photo.id + "_" + photo.secret + ".jpg",
                  source_url = "https://secure.flickr.com/photos/" + photo.owner + "/" + photo.id;

              $dialog.find(".results").append(
                $('<div class="image" style="float: left; padding: 2px; cursor: pointer;"/>')
                .append($('<img/>', {
                  data: {
                    source: source_url,
                    big_image_url: big_image_url
                  },
                  'class': "image_link",
                  src: image_url,
                  tabindex: "0",
                  title: "embed " + (photo.title || ""),
                  alt: photo.title || ""
                }))
              );
            }
          } else {
            $dialog.find(".results").empty().append(htmlEscape(I18n.t('errors.search_failed', "Search failed, please try again.")));
          }
        });
        var query = encodeURIComponent($dialog.find(".query").val());
        // this request will be handled by window.jsonFlickerApi()
        $.getScript("https://secure.flickr.com/services/rest/?method=flickr.photos.search&format=json&api_key=734839aadcaa224c4e043eaf74391e50&per_page=25&license=1,2,3,4,5,6&sort=relevance&text=" + query);
      });

      var insertImage = function(image){
        $dialog.dialog('close');
        callback({
          image_url: $(image).data('big_image_url') || $(image).attr('src'),
          link_url: $(image).data('source'),
          title: $(image).attr('alt')
        });
      }

      $dialog.delegate('.image_link', 'click', function(event) {
        event.preventDefault();
        insertImage(this);
      });

      $dialog.delegate('.image_link','keyup', function(event) {
        event.preventDefault();
        var code = event.keyCode || event.which;
        if(code == 13) { //Enter keycode
          insertImage(this);
        }
      });
    }
    $dialog.find("form img").attr('src', '/images/' + service_type + '_small_icon.png');
    var url = $("#editor_tabs .bookmark_search_url").attr('href');
    url = $.replaceTags(url, 'service_type', service_type);
    $dialog.data('reference_url', url || '')
    $dialog.find(".results").empty();
    $dialog.find(".query").val("");
    $dialog.dialog({
      title: I18n.t('titles.image_search', "Image Search: %{service_name}", {service_name: $.titleize(service_type)}),
      width: 440,
      open: function() {
        $dialog.find("input:visible:first").focus().select();
      },
      height: 320
    });
  };

  $.toSentence = function(array, options) {
    if (typeof options == 'undefined') {
      options = {};
    } else if (options == 'or') {
      options = {
        two_words_connector: I18n.t('#support.array.or.two_words_connector'),
        last_word_connector: I18n.t('#support.array.or.last_word_connector')
      };
    }

    options = $.extend({
        words_connector: I18n.t('#support.array.words_connector'),
        two_words_connector: I18n.t('#support.array.two_words_connector'),
        last_word_connector: I18n.t('#support.array.last_word_connector')
      }, options);

    switch (array.length) {
      case 0:
        return '';
      case 1:
        return '' + array[0];
      case 2:
        return array[0] + options.two_words_connector + array[1];
      default:
        return array.slice(0, -1).join(options.words_connector) + options.last_word_connector + array[array.length - 1];
    }
  }

  // return query string parameter
  // $.queryParam("name") => qs value or null
  $.queryParam = function(name) {
    name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
    var regex = new RegExp("[\\?&]"+name+"=([^&#]*)");
    var results = regex.exec(window.location.search);
    if(results == null)
      return results;
    else
      return decodeURIComponent(results[1].replace(/\+/g, " "));
  };

  $.capitalize = function(string) {
    return string.charAt(0).toUpperCase() + string.substring(1).toLowerCase();
  };

  INST.youTubeRegEx = /^https?:\/\/(www\.youtube\.com\/watch.*v(=|\/)|youtu\.be\/)([^&#]*)/;
  $.youTubeID = function(path) {
    var match = path.match(INST.youTubeRegEx);
    if(match && match[match.length - 1]) {
      return match[match.length - 1];
    }
    return null;
  };
});
