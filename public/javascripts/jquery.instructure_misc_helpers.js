/*
 * Copyright (C) 2011 - present Instructure, Inc.
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
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import INST from './INST'
import I18n from 'i18n!instructure_misc_helpers'
import $ from 'jquery'
import _ from 'underscore'
import htmlEscape from './str/htmlEscape'
import TextHelper from 'compiled/str/TextHelper'
import './jquery.ajaxJSON'
import './jquery.instructure_forms'
import 'jqueryui/dialog'
import './vendor/jquery.scrollTo'

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
      var part = str.charCodeAt(i).toString(16);
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
  // note that raw returns a SafeString object, so you may want to call toString
  // if you're using it elsewhere
  $.raw = function(str) {
    return new htmlEscape.SafeString(str);
  }
  // ensure the jquery html setters don't puke if given a SafeString
  $.each(["html", "append", "prepend"], function(idx, method) {
    var orig = $.fn[method];
    $.fn[method] = function() {
      var args = [].slice.call(arguments);
      for (var i = 0, len = args.length; i < len; i++) {
        if (args[i] instanceof htmlEscape.SafeString)
          args[i] = args[i].toString();
      }
      return orig.apply(this, args);
    }
  });

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
      msie: (/msie/.test( userAgent ) || (/trident/.test( userAgent ))) && !(/opera/.test( userAgent )),
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
