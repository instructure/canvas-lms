/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import $ from 'jquery'
import htmlEscape from '../../str/htmlEscape'
import LinkableEditor from './linkable_editor'
import {send} from 'jsx/shared/rce/RceCommandShim'
import '../../jquery.instructure_misc_helpers'
import 'jqueryui/dialog'
import '../../jquery.instructure_misc_plugins'
import YouTubeApi from './youtube_api'


  // TODO: Allow disabling of inline media as well.  Right now
  // the link is just '#' so disabling it actually ruins it.  It'd
  // be nice if the link were a URL to download the media file.
  var inlineContentClasses = ["instructure_scribd_file"];
  // Only allow non-intrusive types to be auto-opened (i.e. don't
  // allow auto-playing of video files on page load)
  var autoShowContentClasses = ["instructure_scribd_file"];

  var initializedEditors = new WeakMap();

  /**
   * Finds the closest img tag and extracts the 'src' attribute,
   * which then gets pulled into a new string as the src attribute
   * for an img tag to be written through into a tinymce IFrame editor.
   *
   * @param {JQuery Object} target the dom element to grab the nearest img to
   *
   * @returns {string} an image tag string with the src pulled in
   */
  function buttonToImg (target) {
    var src = target.closest('img').attr('src');
    return "<img src='" + htmlEscape(src) + "'/>";
  }

  /**
   * snapshots the current state of the editor (nodeChanged) so that a refocus
   * later will git the right selection involved, then wraps the editor
   * in a linkable editor which knows some of the selection state
   * at the time of link activation and can proxy the actual link call
   * through to our custom linkification method in tinymce.editor_box
   *
   * @param {tinymce.Editor} editor the instance we want to linkify something
   *   within
   *
   * @returns {LinkableEditor}
   */
  function prepEditorForDialog (editor) {
    editor.nodeChanged();
    return new LinkableEditor(editor);
  }

  /**
   * When inserting a link into the editor, we only want to have control
   * classes on them if they've been explicitly asked for through
   * the UI checkboxes.  This function is used to transform
   * link attributes at the time of edit/insertion. It strips off any
   * control classes that are prexisting, and then only adds them on
   * if the checkboxes are populated.
   *
   * @param {String} priorClasses existing class list from the link
   *   element (which would be empty for new links, populated for editing
   *   links)
   *
   * @param {JQuery Object} box the dialog box the UI for creating a link
   *   is within
   *
   * @returns {String} a transformed class list based on the rules listed
   *   above
   */
  function buildLinkClasses (priorClasses, $box) {
    var classes = priorClasses.replace(/(auto_open|inline_disabled)/g, "");
    if($box.find(".auto_show_inline_content").attr("checked")) {
      classes = classes + " auto_open";
    }
    if($box.find(".disable_inline_content").attr('checked')) {
      classes = classes + " inline_disabled";
    }
    return classes;
  }

  /**
   * this takes the dialog box that provides the form for inputting
   * a link target, clears off any submit callbacks that are currently
   * attached to it, and attaches a *new* submit callback to populate
   * link data into the correct editor.
   *
   * @param {JQuery Object} box this is the dialog box div we want to address
   *
   * @param {LinkableEditor} linkableEditor the wrapped editor that knows how
   *  to attach links to selected content
   *
   * @param {function} fetchClasses I hate that we need this parameter.
   *   the priorClasses state is maintained in a pseudo-global string
   *   that gets modulated throughout the life of this plugin.  That
   *   means just passing it in at the time we do the binding gives us
   *   a blank value.  The callback delays the query until the submit
   *   button fires, by which time priorClasses might be populated.  The
   *   real solution here is to de-global-ify the priorClasses variable,
   *   but that refactor is for another day.
   *
   * @param {function} done any behavior you want to happen after the link
   *   has been inserted into the editor
   */
  function bindLinkSubmit ($box, linkableEditor, fetchClasses, done) {
    var $form = $box.find("#instructure_link_prompt_form");
    $form.off('submit');
    $form.on('submit', function(event) {
      event.preventDefault();
      event.stopPropagation();
      var $editor = $box.data('editor');
      var text = $(this).find(".prompt").val();
      var alt = $box.find('.inst-link-preview-alt input').val()
      var classes = buildLinkClasses(fetchClasses.call(), $box);
      var dataAttrs = {'preview-alt': alt}
      $box.dialog("close");
      linkableEditor.createLink(text, classes, dataAttrs);
      done.call();
    });
  }

  function renderDialog (ed) {
    var linkableEditor = prepEditorForDialog(ed);
    var $editor = linkableEditor.getEditor();
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
                send($editor, 'create_link', {
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
          .append('<div class="inst-link-preview-alt" style="display: none;"><label>Alt text for inline preview: <input type="text" style="display: block;" /></label></div>')
          .append("<div class='disable_enhancement' style='display: none;'><input type='checkbox' class='disable_inline_content' id='disable_inline_content'/><label for='disable_inline_content'> Disable inline previews for this link</label></div>")
          .append("<div class='auto_show' style='display: none;'><input type='checkbox' class='auto_show_inline_content' id='auto_show_inline_content'/><label for='auto_show_inline_content'> Auto-open the inline preview for this link</label></div>");

      $box.find(".disable_inline_content").change(function() {
        if($(this).attr('checked')) {
          $box.find(".auto_show_inline_content").attr('checked', false);
        }
        $box.find(".auto_show").showIf(!$(this).attr('checked') && $box.hasClass('for_inline_content_can_auto_show'));
      });
      $box.find(".actions").delegate('.embed_image_link', 'click', function(event) {
        var $editor = $box.data('editor');
        var $target = $(event.target);
        event.preventDefault();
        send($editor, 'insert_code', buttonToImg($target));
        $box.dialog('close');
      });
      // http://img.youtube.com/vi/BOegH4uYe-c/3.jpg
      $box.find(".actions").delegate('.embed_youtube_link', 'click', function(event) {
        event.preventDefault();
        $box.find("#instructure_link_prompt_form").triggerHandler('submit')
      });
      $box.find("#instructure_link_prompt_form .prompt").bind('change keyup', function() {
        var $alt = $box.find('.inst-link-preview-alt');
        $alt.hide();
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
          var checkCompletion = function () {
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
          $alt.show();
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
    } // END of if($box.length == 0), everything above only happens once


    // Bind in the callback to fire when the user has entered
    // the link target they want and hit "submit"
    var fetchClasses = function(){ return priorClasses; };
    var done = function(){ updateLinks(ed, true); };
    bindLinkSubmit($box, linkableEditor, fetchClasses, done);

    $box.data('editor', $editor);
    $box.data('original_data', null);
    var e = ed.selection.getNode();
    while(e.nodeName != 'A' && e.nodeName != 'BODY' && e.parentNode) {
      e = e.parentNode;
    }
    var $a = (e.nodeName == 'A' ? $(e) : null);
    if($a) {
      $box.find(".prompt").val($a.attr('href')).change();
      $box.find('.inst-link-preview-alt input').val($a.data('preview-alt'));
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
        prior_classes: priorClasses,
        preview_alt: $a.data('preview-alt')
      });
      $box.find(".disable_inline_content").attr('checked', $a.hasClass('inline_disabled')).triggerHandler('change');
      $box.find(".auto_show_inline_content").attr('checked', $a.hasClass('auto_open')).triggerHandler('change');
      $box.find(".insert_button").text("Update Link");
    } else {
      $box.find(".prompt").val('').change();
    }
    $box.dialog({
      width: 425,
      height: "auto",
      title: "Link to Website URL",
      open: function() {
        $(this).find(".prompt").focus().select();
      }
    });
  }

  function updateLinks (ed, arg) {
    updateLinks.counter = updateLinks.counter || 0;
    if(arg == true && updateLinks.counter != 0) {
      updateLinks.counter = (updateLinks.counter + 1) % 5;
    } else {
      $(ed.getBody()).find("a").each(function() {
        const yt_api = new YouTubeApi()
        const $link = $(this);
        if ($link.attr('href') && !$link.hasClass('inline_disabled') && $link.attr('href').match(INST.youTubeRegEx)) {
          const yttFailCnt = +$link.attr('data-ytt-failcnt') || 0
          $link.addClass('youtube_link_to_box');
          if ($link.text() === $link.attr('href') && yttFailCnt < 1) {
            yt_api.titleYouTubeText($link)
          }
        }
      });
    }
  }

  function initEditor (ed) {
    if (initializedEditors.get(ed) || ed.on === undefined) {
      return
    }
    ed.on('PreProcess', function(event) {
      $(event.node).find("a.youtube_link_to_box").removeClass('youtube_link_to_box');
      $(event.node).find("img.iframe_placeholder").each(function() {
        var $holder = $(this);
        var $frame = $("<iframe/>");
        var height = $holder.attr('height') || $holder.css('height');
        var width = $holder.hasClass('fullWidth') ? '100%' : $holder.attr('width') || $holder.css('width');

        $holder.attr('width', width);
        $holder.css('width', width);
        $frame.attr('src', $holder.attr('rel'));
        $frame.attr('style', $holder.attr('_iframe_style'));
        if (!$frame[0].style.height.length) {
          $frame.attr('height', height);
          $frame.css('height', height);
        }
        if (!$frame[0].style.width.length) {
          $frame.attr('width', width);
          $frame.css('width', width);
        }
        $(this).after($frame);
        $(this).remove();
      });
    });
    ed.on('change', function() { updateLinks(ed); });
    ed.on('SetContent', function() { updateLinks(ed, "contentJustSet"); } );
    initializedEditors.set(ed, true)
  }

  export default {
    buttonToImg: buttonToImg,
    prepEditorForDialog: prepEditorForDialog,
    buildLinkClasses: buildLinkClasses,
    bindLinkSubmit: bindLinkSubmit,
    renderDialog: renderDialog,
    updateLinks: updateLinks,
    initEditor: initEditor
  }
