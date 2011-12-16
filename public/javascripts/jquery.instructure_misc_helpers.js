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
if (!this.INST) this.INST = {};
I18n.scoped('instructure', function(I18n) {
  
  // Generate a unique integer id (unique within the entire window).
  // Useful for temporary DOM ids.
  // if you pass it a prefix (because all dom ids have to have a alphabetic prefix) it will 
  // make sure that there is no other element on the page with that id.
  var idCounter = 10001;
  $.uniqueId = function(prefix){
    do {
      var id = (prefix || '') + idCounter++;
    } while (prefix && $('#' + id).length);
    return id;
  };
  
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
  
  $.mimeClass = function(contentType){
    return {
      "video/mp4": "video",
      "application/x-rar-compressed": "zip",
      "application/vnd.oasis.opendocument.spreadsheet": "xls",
      "application/x-docx": "doc",
      "application/x-shockwave-flash": "flash",
      "audio/x-mpegurl": "audio",
      "image/png": "image",
      "text/xml": "code",
      "video/x-ms-asf": "video",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": "xls",
      "text/html": "html",
      "video/x-msvideo": "video",
      "audio/x-pn-realaudio": "audio",
      "application/x-zip-compressed": "zip",
      "text/css": "code",
      "video/x-sgi-movie": "video",
      "audio/x-aiff": "audio",
      "application/zip": "zip",
      "application/xml": "code",
      "application/x-zip": "zip",
      "text/rtf": "doc",
      "text": "text",
      "video/mpeg": "video",
      "video/quicktime": "video",
      "audio/3gpp": "audio",
      "audio/mid": "audio",
      "application/x-rar": "zip",
      "image/x-psd": "image",
      "application/vnd.ms-excel": "xls",
      "application/msword": "doc",
      "video/x-la-asf": "video",
      "image/gif": "image",
      "application/rtf": "doc",
      "video/3gpp": "video",
      "image/pjpeg": "image",
      "image/jpeg": "image",
      "application/vnd.oasis.opendocument.text": "doc",
      "audio/x-wav": "audio",
      "audio/basic": "audio",
      "audio/mpeg": "audio",
      "application/vnd.openxmlformats-officedocument.presentationml.presentation": "ppt",
      "application/vnd.ms-powerpoint": "ppt",
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document": "doc",
      "application/pdf": "pdf",
      "text/plain": "text",
      "text/x-csharp": "code"
    }[contentType] || 'file'
  }
  
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
  
  var $dummyElement = $('<div/>');
  $.htmlEscape = $.h = function(str) {
    return str && str.htmlSafe ?
      str.toString() :
      $dummyElement.text(str).html();
  }

  // escape all string values (not keys) in an object
  $.htmlEscapeValues = function(obj) {
    var k,v;
    for (k in obj) {
      v = obj[k];
      if (typeof v === "string") {
        obj[k] = $.htmlEscape(v);
      }
    }
  }

  // useful for i18n, e.g. t('key', 'pick one: %{select}', {select: $.raw('<select><option>...')})
  // note that raw returns a String object, so you may want to call toString
  // if you're using it elsewhere
  $.raw = function(str) {
    str = new String(str);
    str.htmlSafe = true;
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
          $body = $('body'),
          $main = $('#main'),
          $not_right_side = $("#not_right_side"),
          $window = $(window),
          headerHeight = $right_side.offset().top,
          rightSideMarginBottom = $("#right-side-wrapper").height() - $right_side.outerHeight();
          
      function onScroll(){
        var windowScrollTop = $window.scrollTop(),
            windowScrollIsBelowHeader = (windowScrollTop > headerHeight);
        if (windowScrollIsBelowHeader) {
          var notRightSideHeight = $not_right_side.height(),
              rightSideHeight = $right_side.height(),
              notRightSideIsTallerThanRightSide = notRightSideHeight > rightSideHeight,
              rightSideBottomIsBelowMainBottom = ( headerHeight + $main.height() - windowScrollTop ) <= ( rightSideHeight + rightSideMarginBottom );
        }
        // windows chrome repaints when you set the class, even if the classes
        // aren't truly changing, which wreaks havoc on open select elements.
        // so we only toggle if we really need to
        if ((windowScrollIsBelowHeader && notRightSideIsTallerThanRightSide && !rightSideBottomIsBelowMainBottom) ^ $body.hasClass('with-scrolling-right-side')) {
          $body.toggleClass('with-scrolling-right-side');
        }
        if ((windowScrollIsBelowHeader && notRightSideIsTallerThanRightSide && rightSideBottomIsBelowMainBottom) ^ $body.hasClass('with-sidebar-pinned-to-bottom')) {
          $body.toggleClass('with-sidebar-pinned-to-bottom');
        }
      }
      var throttledOnScroll = $.throttle(50, onScroll);
      throttledOnScroll();
      $window.scroll(throttledOnScroll);
      setInterval(throttledOnScroll, 1000);
      scrollSideBarIsBound = true;
    }
  };

  $.keys = function(object){
    var results = [];
    for (var property in object)
      results.push(property);
    return results;
  };
  
  $.underscore = function(string) {
    return (string || "").replace(/([A-Z])/g, "_$1").replace(/^_/, "").toLowerCase();
  };
  
  $.titleize = function(string) {
    var res = (string || "").replace(/([A-Z])/g, " $1").replace(/_/g, " ").replace(/\s+/, " ").replace(/^\s/, "");
    return $.map(res.split(/\s/), function(word) { return (word[0] || "").toUpperCase() + word.substring(1); }).join(" ");
  };

  // ported pluralizations from active_support/inflections.rb
  // (except for cow -> kine, because nobody does that) 
  var pluralize = {
    skip: ['equipment', 'information', 'rice', 'money', 'species', 'series', 'fish', 'sheep', 'jeans'],
    patterns: [
      [/person$/i, 'people'],
      [/man$/i, 'men'],
      [/child$/i, 'children'],
      [/sex$/i, 'sexes'],
      [/move$/i, 'moves'],
      [/(quiz)$/i, '$1zes'],
      [/^(ox)$/i, '$1en'],
      [/([m|l])ouse$/i, '$1ice'],
      [/(matr|vert|ind)(?:ix|ex)$/i, '$1ices'],
      [/(x|ch|ss|sh)$/i, '$1es'],
      [/([^aeiouy]|qu)y$/i, '$1ies'],
      [/(hive)$/i, '$1s'],
      [/(?:([^f])fe|([lr])f)$/i, '$1$2ves'],
      [/sis$/i, 'ses'],
      [/([ti])um$/i, '$1a'],
      [/(buffal|tomat)o$/i, '$1oes'],
      [/(bu)s$/i, '$1ses'],
      [/(alias|status)$/i, '$1es'],
      [/(octop|vir)us$/i, '$1i'],
      [/(ax|test)is$/i, '$1es'],
      [/s$/i, 's']
    ]
  };
  $.pluralize = function(string) {
    string = string || '';
    if ($.inArray(string, pluralize.skip) > 0) {
      return string;
    }
    for (var i = 0; i < pluralize.patterns.length; i++) {
      var pair = pluralize.patterns[i];
      if (string.match(pair[0])) {
        return string.replace(pair[0], pair[1])
      }
    }
    return string + "s";
  };
  
  $.pluralize_with_count = function(count, string) {
    return "" + count + " " + (count == 1 ? string : $.pluralize(string));
  }
  
  $.parseUserAgentString = function(userAgent) {
    userAgent = (userAgent || "").toLowerCase();
    var data = {
      version: (userAgent.match( /.+(?:me|ox|it|ra|ie|er)[\/: ]([\d.]+)/ ) || [0,null])[1],
      chrome: /chrome/.test( userAgent ),
      safari: /webkit/.test( userAgent ),
      opera: /opera/.test( userAgent ),
      msie: /msie/.test( userAgent ) && !(/opera/.test( userAgent )),
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
  
  $.uniq = function(array) {
    var result = [];
    var hash = {};
    for(var idx in array) {
      if(!hash[array[idx]]) {
        hash[array[idx]] = true;
        result.push(array[idx]);
      }
    }
    return result;
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
                       "<button class='button search_button' type='submit'>" +
                       $.h(I18n.t('buttons.search', "Search")) + "</button></form>");
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
            .append($.h(I18n.t('status.diigo_search_throttling', "Diigo limits users to one search every ten seconds.  Please wait...")));
          return;
        }
        $dialog.find(".results").empty().append($.h(I18n.t('status.searching', "Searching...")));
        lastLookup = new Date();
        var query = $dialog.find(".query").val();
        var url = $.replaceTags($dialog.data('reference_url'), 'query', query);
        $.ajaxJSON(url, 'GET', {}, function(data) {
          $dialog.find(".results").empty();
          if( !data.length ) {
            $dialog.find(".results").append($.h(I18n.t('no_results_found', "No Results Found")));
          }
          for(var idx in data) {
            data[idx].short_title = data[idx].title;
            if(data[idx].title == data[idx].description) {
              data[idx].short_title = $.truncateText(data[idx].description, 30);
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
            .append($.h(I18n.t('errors.search_failed', "Search failed, please try again.")));
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
    $dialog.dialog('close').dialog({
      autoOpen: false,
      title: I18n.t('titles.bookmark_search', "Bookmark Search: %{service_name}", {service_name: $.titleize(service_type)}),
      open: function() {
        $dialog.find("input:visible:first").focus().select();
      },
      width: 400
    }).dialog('open');
  };
  
  $.findImageForService = function(service_type, callback) {
    var $dialog = $("#instructure_image_search");
    $dialog.find("button").attr('disabled', false);
    if( !$dialog.length ) {
      $dialog = $("<div id='instructure_image_search'/>")
                  .append("<form id='image_search_form' style='margin-bottom: 5px;'>" +
                            "<img src='/images/flickr_creative_commons_small_icon.png'/>&nbsp;&nbsp;" + 
                            "<input type='text' class='query' style='width: 250px;' title='" +
                            $.h(I18n.t('tooltips.enter_search_terms', "enter search terms")) + "'/>" + 
                            "<button class='button' type='submit'>" +
                            $.h(I18n.t('buttons.search', "Search")) + "</button></form>")
                  .append("<div class='results' style='max-height: 240px; overflow: auto;'/>");
      
      $dialog.find("form .query").formSuggestion();
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
                  image_url = "http://farm" + photo.farm + ".static.flickr.com/" + photo.server + "/" + photo.id + "_" + photo.secret + "_s.jpg",
                  big_image_url = "http://farm" + photo.farm + ".static.flickr.com/" + photo.server + "/" + photo.id + "_" + photo.secret + ".jpg",
                  source_url = "http://www.flickr.com/photos/" + photo.owner + "/" + photo.id;
                  
              $dialog.find(".results").append(
                $('<div class="image" style="float: left; padding: 2px; cursor: pointer;"/>')
                .append($('<img/>', {
                  data: {
                    source: source_url,
                    big_image_url: big_image_url
                  },
                  'class': "image_link",
                  src: image_url,
                  title: "embed " + (photo.title || ""),
                  alt: photo.title || ""  
                }))
              );
            }
          } else {
            $dialog.find(".results").empty().append($.h(I18n.t('errors.search_failed', "Search failed, please try again.")));
          }
        });
        var query = encodeURIComponent($dialog.find(".query").val());
        // this request will be handled by window.jsonFlickerApi()
        $.getScript("http://www.flickr.com/services/rest/?method=flickr.photos.search&format=json&api_key=734839aadcaa224c4e043eaf74391e50&per_page=25&license=1,2,3,4,5,6&sort=relevance&text=" + query);
      });
      $dialog.delegate('.image_link', 'click', function(event) {
        event.preventDefault();
        $dialog.dialog('close');
        callback({
          image_url: $(this).data('big_image_url') || $(this).attr('src'),
          link_url: $(this).data('source'),
          title: $(this).attr('alt')
        });
      });
    }
    $dialog.find("form img").attr('src', '/images/' + service_type + '_small_icon.png');
    var url = $("#editor_tabs .bookmark_search_url").attr('href');
    url = $.replaceTags(url, 'service_type', service_type);
    $dialog
      .data('reference_url', url)
      .find(".results").empty().end()
      .find(".query").val("").end()
      .dialog('close')
      .dialog({
        autoOpen: false,
        title: I18n.t('titles.image_search', "Image Search: %{service_name}", {service_name: $.titleize(service_type)}),
        width: 440,
        open: function() {
          $dialog.find("input:visible:first").focus().select();
        },
        height: 320
      })
      .dialog('open');
  };
  
  $.truncateText = function(string, max) {
    max = max || 30;
    if ( !string ) { 
      return ""; 
    } else {
      var split  = (string || "").split(/\s/),
          result = "",
          done   = false;
          
      for(var idx in split) {
        var val = split[idx];
        if ( done ) {
          // do nothing
        } else if( val && result.length < max) {
          if(result.length > 0) {
            result += " ";
          }
          result += val;
        } else {
          done = true;
          result += "...";
        }
      }
      return result;
    }
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
  
  $.regexEscape = function(string) {
    return string.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&");
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
  
  // tells you how many keys are in an object, 
  // so: $.size({})  === 0  and $.size({foo: "bar"}) === 1
  $.size = function(object) {
    var keyCount = 0;
    $.each(object,function(){ keyCount++; });
    return keyCount;
  };
  
  $.capitalize = function(string) {
    return string.charAt(0).toUpperCase() + string.substring(1).toLowerCase();
  };
  
  var storage_user_id;
  function getUser() {
    if ( !storage_user_id ) {
      storage_user_id = $.trim($("#identity .user_id").text());
    }
    return storage_user_id;
  };
  
  $.store.userGet = function(key) {
    return $.store.get("_" + getUser() + "_" + key);
  };
  
  $.store.userSet = function(key, value) {
    return $.store.set("_" + getUser() + "_" + key, value);
  };
  
  $.store.userRemove = function(key, value) {
    return $.store.remove("_" + getUser() + "_" + key, value);
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