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
  'compiled/editor/stocktiny',
  'jquery',
  'str/htmlEscape',
  'jquery.instructure_misc_helpers',
  'jqueryui/dialog',
  'jquery.instructure_misc_plugins',
], function(tinymce, $, htmlEscape) {

  var lastLookup = null;


  /**
   * A module for holding helper functions pulled out of the mess below.
   *
   * This should make it easy to seperate and test logic as this evolves
   * without splitting out another module, and since the plugin gets
   * registered with tinymce rather than returned, we can return this
   * object at the end of the module definition as an export for unit testing.
   *
   * @exports
   */
  var Links = {

    /**
     * Finds the closes img tag and extracts the 'src' attribute,
     * which then gets pulled into a new string as the src attribute
     * for an img tag to be written through into a tinymce IFrame editor.
     *
     * @param {JQuery Object} target the dom element to grab the nearest img to
     *
     * @returns {string} an image tag string with the src pulled in
     */
    buttonToImg: function(target){
      var src = target.closest('img').attr('src');
      return "<img src='" + htmlEscape(src) + "'/>";
    }
  };

  // hack for circular dependency
  if (!$.fn.editorBox) {
    console && console.log('tinymce.editor_box not loaded yet');
    require(['tinymce.editor_box']);
  }

    tinymce.create('tinymce.plugins.InstructureLinks', {
      init : function(ed, url) {
        var promptInteraction = {};
        // TODO: Allow disabling of inline media as well.  Right now
        // the link is just '#' so disabling it actually ruins it.  It'd
        // be nice if the link were a URL to download the media file.
        var inlineContentClasses = ['instructure_scribd_file'];
        // Only allow non-intrusive types to be auto-opened (i.e. don't
        // allow auto-playing of video files on page load)
        var autoShowContentClasses = ['instructure_scribd_file'];
        ed.addCommand('instructureLinks', function() {
          var $editor = $("#" + ed.id);
          if ($editor.data('enable_bookmarking')) {
            var bookmark = ed.selection && ed.selection.getBookmark();
            $editor.data('last_bookmark', bookmark);
          }
          var $box = $("#instructure_link_prompt");
          var priorClasses = '';
          $box.removeClass('for_inline_content')
            .find(".disable_enhancement").hide().end()
            .find(".auto_show").hide().end()
            .find(".insert_button").text("Insert Link").end()
            .find(".disable_inline_content").attr('checked', false).end()
            .find(".auto_show_inline_content").attr('checked', false);
          if($box.length == 0) {
            var $box = $(document.createElement('div'));
            $.getUserServices("BookmarkService", function(data) {
              var $editor = $box.data('editor');
              var $services = $("<div style='text-align: left; margin-left: 20px;'/>");
              var service, $service;
              for(var idx in data) {
                service = data[idx].user_service;
                if(service) {
                  $service = $("<a href='#' class='bookmark_service no-hover'/>");
                  $service.addClass(service.service);
                  $service.data('service', service);
                  $service.attr('title', 'Find links using ' + service.service);
                  var $img = $("<img/>");
                  $img.attr('src', '/images/' + service.service + '_small_icon.png');
                  $service.append($img);
                  $service.click(function(event) {
                    event.preventDefault();
                    $("#instructure_link_prompt").dialog('close');
                    $.findLinkForService($(this).data('service').service, function(data) {
                      $("#instructure_link_prompt").dialog('close');
                      $editor.editorBox('create_link', {
                        title: data.title,
                        url: data.url,
                        classes: priorClasses
                      });
                    });
                  });
                  $services.append($service);
                  $services.append("&nbsp;&nbsp;");
                }
              }
              $box.find("#instructure_link_prompt_form").after($services);
            });
            $box.append("<p><em>This will make the selected text a link, or insert a new link if nothing is selected.</em></p> <label for='instructure_link_prompt_form_input'>Paste or type a url or wiki page in the box below:</label><form id='instructure_link_prompt_form' class='form-inline'><input type='text' id='instructure_link_prompt_form_input' class='prompt' class='btn' value='http://'/> <button type='submit' class='insert_button btn'>Insert Link</button></form>")
                .append("<div class='actions'></div><div class='clear'></div>")
                .append("<div class='disable_enhancement' style='display: none;'><input type='checkbox' class='disable_inline_content' id='disable_inline_content'/><label for='disable_inline_content'> Disable inline previews for this link</label></div>")
                .append("<div class='auto_show' style='display: none;'><input type='checkbox' class='auto_show_inline_content' id='auto_show_inline_content'/><label for='auto_show_inline_content'> Auto-open the inline preview for this link</label></div>");

            $box.find(".disable_inline_content").change(function() {
              if($(this).attr('checked')) {
                $box.find(".auto_show_inline_content").attr('checked', false);
              }
              $box.find(".auto_show").showIf(!$(this).attr('checked') && $box.hasClass('for_inline_content_can_auto_show'));
            });
            $box.find("#instructure_link_prompt_form").submit(function(event) {
              var $editor = $box.data('editor');
              event.preventDefault();
              event.stopPropagation();
              var text = $(this).find(".prompt").val();
              if(!text.match(/^[a-zA-Z]+:\/\//) && !text.match(/^[0-9a-zA-Z]+\.[0-9a-zA-Z]+/) && text.match(/^[0-9a-zA-Z\s]+$/)) {
                wiki_url = $("#wiki_sidebar_wiki_url").attr('href');
                if(wiki_url) {
                  text = $.replaceTags(wiki_url, 'page_url', text.replace(/\s/, '-').toLowerCase());
                }
              }
              var classes = priorClasses.replace(/(auto_open|inline_disabled)/g, "");
              if($box.find(".auto_show_inline_content").attr('checked')) {
                classes = classes + " auto_open";
              }
              if($box.find(".disable_inline_content").attr('checked')) {
                classes = classes + " inline_disabled";
              }
              $editor.editorBox('create_link', {
                url: text,
                classes: classes
              });
              $box.dialog('close');
              updateLinks(true);
            });
            $box.find(".actions").delegate('.embed_image_link', 'click', function(event) {
              var $editor = $box.data('editor');
              var $target = $(event.target);
              event.preventDefault();
              $editor.editorBox('insert_code', Links.buttonToImg($target));
              $box.dialog('close');
            });
            // http://img.youtube.com/vi/BOegH4uYe-c/3.jpg
            $box.find(".actions").delegate('.embed_youtube_link', 'click', function(event) {
              var $editor = $box.data('editor');
              event.preventDefault();
              $editor.editorBox('create_link', $(event.target).closest('img').attr('alt'));
              $box.dialog('close');
            });
            $box.find("#instructure_link_prompt_form .prompt").bind('change keyup', function() {
              $("#instructure_link_prompt .actions").empty();
              var val = $(this).val();
              // If the user changes the link then it should no longer
              // have inline content classes or be configurable
              var data = $box.data('original_data');
              if(!data || val != data.url) {
                $box.removeClass('for_inline_content').removeClass('for_inline_content_can_auto_show');
                var re = new RegExp("(" + inlineContentClasses.join('|') + ")", 'g');
                priorClasses = priorClasses.replace(re, "");
              } else {
                $box.toggleClass('for_inline_content', data.for_inline_content)
                  .toggleClass('for_inline_content_can_auto_show', data.for_inline_content_can_auto_show)
                  .find(".disable_enhancement").showIf(data.for_inline_content).end()
                  .find(".auto_show").showIf(data.for_inline_content_can_auto_show);
                priorClasses = data.prior_classes;
              }
              var hideDisableEnhancement = !$box.hasClass('for_inline_content');
              var hideShowInline = !$box.hasClass('for_inline_content_can_auto_show');

              if(val.match(/\.(gif|png|jpg|jpeg)$/)) {
                var $div = $(document.createElement('div'));
                $div.css('textAlign', 'center');
                var $img = $(document.createElement('img'));
                $img.attr('src', val);
                $img.addClass('embed_image_link');
                $img.css('cursor', 'pointer');
                var img = new Image();
                img.src = val;
                function checkCompletion() {
                  if(img.complete) {
                    if(img.height < 100 || (img.height > 100 && img.height < 200)) {
                      $img.height(img.height);
                    }
                  } else {
                    setTimeout(checkCompletion, 500);
                  }
                }
                setTimeout(checkCompletion, 500);
                $img.height(100);
                $img.attr('title', 'Click to Embed the Image');
                $div.append($img);
                $("#instructure_link_prompt .actions").append($div);
              } else if(val.match(INST.youTubeRegEx)) {
                var id = $.youTubeID(val); //val.match(INST.youTubeRegEx)[2];
                var $div = $(document.createElement('div'));
                $div.css('textAlign', 'center');
                if(!$box.find(".disable_inline_content").attr('checked') && $box.hasClass('for_inline_content_can_auto_show')) {
                  $box.find(".auto_show").show();
                }
                hideDisableEnhancement = false;
                $box.find(".disable_enhancement").show();
                var $img = $(document.createElement('img'));
                $img.attr('src', 'http://img.youtube.com/vi/' + id + '/2.jpg');
                $img.css({paddingLeft: 100, background: "url(/images/youtube_logo.png) no-repeat left center", height: 90, display: 'inline-block'});
                $img.attr('alt', val);
                $img.addClass('embed_youtube_link');
                $img.css('cursor', 'pointer');
                $img.attr('title', 'Click to Embed YouTube Video');
                $div.append($img);
                $("#instructure_link_prompt .actions").append($div);
              }
              if(hideDisableEnhancement) {
                $box.find(".disable_enhancement").hide();
                $box.find(".disable_inline_content").attr('checked', false);
              }
              if(hideShowInline) {
                $box.find(".auto_show").hide();
                $box.find(".auto_show_inline_content").attr('checked', false);
              }
            });
            $box.attr('id', 'instructure_link_prompt');
            $("body").append($box);
          }
          $box.data('editor', $editor);
          $box.data('original_data', null);
          var e = ed.selection.getNode();
          while(e.nodeName != 'A' && e.nodeName != 'BODY' && e.parentNode) {
            e = e.parentNode;
          }
          var $a = (e.nodeName == 'A' ? $(e) : null);
          if($a) {
            $box.find(".prompt").val($a.attr('href')).change();
            priorClasses = ($a.attr('class') || '').replace(/youtube_link_to_box/, '');
            var re = new RegExp("(" + inlineContentClasses.join('|') + ")");
            if(($a.attr('class') || '').match(re)) {
              $box.addClass('for_inline_content')
                .find(".disable_enhancement").show();
            }
            var re = new RegExp("(" + autoShowContentClasses.join('|') + ")");
            if(($a.attr('class') || '').match(re)) {
              $box.addClass('for_inline_content_can_auto_show')
                .find(".auto_show").show();
            }
            $box.data('original_data', {
              url: $a.attr('href'),
              for_inline_content: $box.hasClass('for_inline_content'),
              for_inline_content_can_auto_show: $box.hasClass('for_inline_content_can_auto_show'),
              prior_classes: priorClasses
            });
            $box.find(".disable_inline_content").attr('checked', $a.hasClass('inline_disabled')).triggerHandler('change');
            $box.find(".auto_show_inline_content").attr('checked', $a.hasClass('auto_open')).triggerHandler('change');
            $box.find(".insert_button").text("Update Link");
          }
          $box.dialog({
            width: 425,
            height: "auto",
            title: "Link to Website URL",
            open: function() {
              $(this).find(".prompt").focus().select();
            }
          });
        });

        ed.addButton('instructure_links', {
          title: 'Link to URL',
          cmd: 'instructureLinks',
          image: url + '/img/button.gif',
          onPostRender: function(){
            var btn = this;
            ed.on('NodeChange', function(event) {
              while(event.nodeName != 'A' && event.nodeName != 'BODY' && event.parentNode) {
                event = event.parentNode;
              }
              btn.active(event.nodeName == 'A');
            });
          }
        });

        function updateLinks(arg) {
          updateLinks.counter = updateLinks.counter || 0;
          if(arg == true && updateLinks.counter != 0) {
            updateLinks.counter = (updateLinks.counter + 1) % 5;
          } else {
            $(ed.getBody()).find("a").each(function() {
              var $link = $(this);
              if ($link.attr('href') && !$link.hasClass('inline_disabled') && $link.attr('href').match(INST.youTubeRegEx)) {
                $link.addClass('youtube_link_to_box');
              }
            });
          }
          $(ed.getBody()).find("iframe").each(function() {
            var $frame = $(this);
            var $link = $("<img/>");
            $link.addClass('iframe_placeholder');
            $link.attr('rel', $frame.attr('src'));
            $link.attr('style', $frame.attr('style'));
            $link.css('display', 'block');
            $link.attr('_iframe_style', $frame.attr('style'));
            var width = ($frame.attr('width') || $frame.css('width'));
            if(width == 'auto') { width = null; }
            if(!width || width == '100%' || width == 'auto') {
              var edWidth = $(ed.contentAreaContainer).width();
              $link.attr('width', edWidth - 15);
              $link.css('width', edWidth - 15);
              $link.addClass('fullWidth');
            } else {
              $link.attr('width', width);
              $link.css('width', width);
            }
            $link.css('margin', 5);
            var split = [];
            var src = $frame.attr('src');
            var sub = "";
            for(var idx = 0; idx < src.length; idx++) {
              sub = sub + src[idx];
              if(src[idx].match(/[^a-zA-Z0-9\.]/) && sub.length > 30) {
                split.push(sub);
                sub = "";
              }
            }
            split.push(sub);;
            $frame.attr('src');
            $link.attr('alt', "This frame will embed the url:\r\n" + split.join("\r\n"));
            $link.attr('title', "This frame will embed the url:\r\n" + split.join("\r\n"));
            var height = $frame.attr('height') || $frame.css('height');
            if(height == 'auto') { height = null; }
            if(!height) {
              $link.attr('height', 300);
              $link.css('height', 300);
            } else {
              $link.attr('height', height);
              $link.css('height', height);
            }
            $link.attr('src', '/images/blank.png');
            $link.css('background', 'transparent url(/images/iframe.png) no-repeat top left'); //about:blank');
            $link.css('border', '1px solid #aaa');
            if($frame.parents("p,div").length == 0) {
              var $p = $("<p/>");
              $p.append($link);
              $link = $p;
            }
            $frame.after($link);
            $frame.remove();
          }).end()
          .find(".iframe_placeholder").each(function() {
            var edWidth = $(ed.contentAreaContainer).width();
            var $holder = $(this);
            if($(ed.contentAreaContainer).hasScrollbar() || true) {
              edWidth -= $(ed.contentAreaContainer).scrollbarWidth();
            }
            if($holder.width() > edWidth - 40) {
              $holder.width(edWidth - 15);
              if(!$holder.hasClass('fullWidth')) { $holder.addClass('fullWidth'); }
            } else {
              if($holder.hasClass('fullWidth')) { $holder.removeClass('fullWidth'); }
            }
          });
        }
        ed.on('PreProcess', function(event) {
          $(event.node).find("a.youtube_link_to_box").removeClass('youtube_link_to_box');
          $(event.node).find("img.iframe_placeholder").each(function() {
            var $holder = $(this);
            var $frame = $("<iframe/>");
            $frame.attr('src', $holder.attr('rel'));
            $frame.attr('style', $holder.attr('_iframe_style'));
            $frame.height($holder.attr('height') || $holder.css('height'));
            if($holder.hasClass('fullWidth')) {
              $holder.attr('width', '100%');
              $holder.css('width', '100%');
            }
            $frame.css('width', $holder.attr('width') || $holder.css('width'));
            $(this).after($frame);
            $(this).remove();
          });
        });
        ed.on('change', function() { updateLinks(); });
        ed.on('SetContent', function() {updateLinks("contentJustSet");} );


      },

      getInfo : function() {
        return {
          longname : 'InstructureLinks',
          author : 'Brian Whitmer',
          authorurl : 'http://www.instructure.com',
          infourl : 'http://www.instructure.com',
          version : tinymce.majorVersion + "." + tinymce.minorVersion
        };
      }
    });

    // Register plugin
    tinymce.PluginManager.add('instructure_links', tinymce.plugins.InstructureLinks);

    return Links;
});
