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

// TinyMCE-jQuery EditorBox plugin
// Called on a jQuery selector (should be a single object only)
// to initialize a TinyMCE editor box in the place of the
// selected textarea: $("#edit").editorBox().  The textarea
// must have a unique id in order to function properly.
// editorBox():
// Initializes the object.  All other methods should
// only be called on an already-initialized box.
// editorBox('focus', [keepTrying])
//   Passes focus to the selected editor box.  Returns
//   true/false depending on whether the focus attempt was
//   successful.  If the editor box has not completely initialized
//   yet, then the focus will fail.  If keepTrying
//   is defined and true, the method will keep trying until
//   the focus attempt succeeds.
// editorBox('destroy')
//   Removes the TinyMCE instance from the textarea.
// editorBox('toggle')
//   Toggles the TinyMCE instance.  Switches back and forth between
//   the textarea and the Tiny WYSIWYG.
// editorBox('get_code')
//   Returns the plaintext code contained in the textarea or WYSIGWYG.
// editorBox('set_code', code)
//   Sets the plaintext code content for the editor box.  Replaces ALL
//   content with the string value of code.
// editorBox('insert_code', code)
//   Inserts the string value of code at the current selection point.
// editorBox('create_link', options)
//   Creates an anchor link at the current selection point.  If anything
//   is selected, makes the selection a link, otherwise creates a link.
//   options.url is used for the href of the link, and options.title
//   will be the body of the link if no text is currently selected.

define([
  'i18nObj',
  'jquery',
  'jsx/shared/rce/editorOptions',
  'compiled/editor/editorAccessibility', /* editorAccessibility */
  'tinymce.editor_box_list',
  'tinymce.config',
  'tinymce.commands',
  'tinymce.editor_box_utils',
  //'compiled/tinymce', // required, but the bundles that ACTUALLY use
                        // tiny can require it themselves or else we have
                        // build problems
  'INST', // for IE detection; need to handle links in a special way
  'decode_string',
  'jqueryui/draggable' /* /\.draggable/ */,
  'jquery.instructure_misc_plugins' /* /\.indicate/ */,
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */,
  'vendor/jquery.ba-tinypubsub'
], function(I18nObj, $, editorOptions,
            EditorAccessibility, EditorBoxList, EditorConfig, EditorCommands,
            Utils, INST, decodeString) {

  var enableBookmarking = !!INST.browser.ie;
  $(document).ready(function() {
    enableBookmarking = !!INST.browser.ie;
  });

  var $instructureEditorBoxList = new EditorBoxList();

  function fillViewportWithEditor(editorID, elementToLeaveInViewport){
    var $iframe = $("#"+editorID+"_ifr");
    if ($iframe.length) {
      var newHeight = $(window).height() - ($iframe.offset().top + elementToLeaveInViewport.height() + 1);
      $iframe.height(newHeight);
    }
    $("#"+editorID+"_tbl").css('height', '');
  }

  function EditorBox(id, search_url, submit_url, content_url, options) {
    options = $.extend({}, options);
    if (options.fullHeight) {
      $(window).resize(function(){
        fillViewportWithEditor(id, options.elementToLeaveInViewport);
      }).triggerHandler('resize');
    }

    var $textarea = $("#" + id);
    $textarea.data('enable_bookmarking', enableBookmarking);
    var width = $textarea.width();
    if(width == 0) {
      width = $textarea.closest(":visible").width();
    }

    var tinyOptions = editorOptions(width, id, options, enableBookmarking, tinymce)
    tinyMCE.init(tinyOptions);

    this._textarea =  $textarea;
    this._editor = null;
    this._id = id;
    this._searchURL = search_url;
    this._submitURL = submit_url;
    this._contentURL = content_url;
    $instructureEditorBoxList._addEditorBox(id, this);
    $textarea.bind('blur change', function() {
      if($instructureEditorBoxList._getEditor(id) && $instructureEditorBoxList._getEditor(id).isHidden()) {
        $(this).editorBox('set_code', $instructureEditorBoxList._getTextArea(id).val());
      }
    });
  }

  var fieldSelection = {

    getSelection: function() {

      var e = this.jquery ? this[0] : this;

      return (

        /* mozilla / dom 3.0 */
        ('selectionStart' in e && function() {
          var l = e.selectionEnd - e.selectionStart;
          return { start: e.selectionStart, end: e.selectionEnd, length: l, text: e.value.substr(e.selectionStart, l) };
        }) ||

        /* exploder */
        (document.selection && function() {

          e.focus();

          var r = document.selection.createRange();
          if (r == null) {
            return { start: 0, end: e.value.length, length: 0 };
          }

          var re = e.createTextRange();
          var rc = re.duplicate();
          re.moveToBookmark(r.getBookmark());
          rc.setEndPoint('EndToStart', re);

          return { start: rc.text.length, end: rc.text.length + r.text.length, length: r.text.length, text: r.text };
        }) ||

        /* browser not supported */
        function() {
          return { start: 0, end: e.value.length, length: 0 };
        }

      )();

    },

    replaceSelection: function() {

      var e = this.jquery ? this[0] : this;
      var text = arguments[0] || '';

      return (

        /* mozilla / dom 3.0 */
        ('selectionStart' in e && function() {
          e.value = e.value.substr(0, e.selectionStart) + text + e.value.substr(e.selectionEnd, e.value.length);
          return this;
        }) ||

        /* exploder */
        (document.selection && function() {
          e.focus();
          document.selection.createRange().text = text;
          return this;
        }) ||

        /* browser not supported */
        function() {
          e.value += text;
          return this;
        }

      )();

    }

  };

  $.extend($.fn, fieldSelection);

// --------------------------------------------------------------------

  var editorBoxIdCounter = 1;

  $.fn.editorBox = function(options, more_options) {
    var args = arguments;
    if(this.length > 1) {
      return this.each(function() {
        var $this = $(this);
        $this.editorBox.apply($this, args);
      });
    }

    var id = this.attr('id');
    if(typeof(options) == "string" && options != "create") {
      if(options == "get_code") {
        return this._getContentCode(more_options);
      } else if(options == "set_code") {
        this._setContentCode(more_options);
      } else if(options == "insert_code") {
        this._insertHTML(more_options);
      } else if(options == "selection_offset") {
        return this._getSelectionOffset();
      } else if(options == "selection_link") {
        return this._getSelectionLink();
      } else if(options == "create_link") {
        this._linkSelection(more_options);
      } else if(options == "focus") {
        return this._editorFocus(more_options);
      } else if(options == "toggle") {
        this._toggleView();
      } else if(options == "execute") {
        var arr = [];
        for(var idx = 1; idx < arguments.length; idx++) {
          arr.push(arguments[idx]);
        }
        return $.fn._execCommand.apply(this, arr);
      } else if(options == "destroy") {
        this._removeEditor(more_options);
      } else if(options == "is_dirty") {
        return $instructureEditorBoxList._getEditor(id).isDirty();
      } else if(options == 'exists?') {
        return !!$instructureEditorBoxList._getEditor(id);
      }
      return this;
    }
    this.data('rich_text', true);
    if(!id) {
      id = 'editor_box_unique_id_' + editorBoxIdCounter++;
      this.attr('id', id);
    }
    if($instructureEditorBoxList._getEditor(id)) {
      this._setContentCode(this.val());
      return this;
    }
    var search_url = "";
    if(options && options.search_url) {
      search_url = options.search_url;
    }
    var box = new EditorBox(id, search_url, "", "", options);
    return this;
  };

  $.fn._execCommand = function() {
    var id = $(this).attr('id');
    var editor = $instructureEditorBoxList._getEditor(id);
    if(editor && editor.execCommand) {
      editor.execCommand.apply(editor, arguments);
    }
    return this;
  };

  $.fn._justGetCode = function() {
    var id = this.attr('id') || '';
    var content = '';
    try {
      if($instructureEditorBoxList._getEditor(id).isHidden()) {
        content = $instructureEditorBoxList._getTextArea(id).val();
      } else {
        content = $instructureEditorBoxList._getEditor(id).getContent();
      }
    } catch(e) {
      if(tinyMCE && tinyMCE.get(id)) {
        content = tinyMCE.get(id).getContent();
      } else {
        content = this.val() || '';
      }
    }
    return content;
  };

  $.fn._getContentCode = function(update) {
    if(update == true) {
      var content = this._justGetCode(); //""
      this._setContentCode(content);
    }
    return this._justGetCode();
  };

  $.fn._getSearchURL = function() {
    return $instructureEditorBoxList._getEditorBox(this.attr('id'))._searchURL;
  };

  $.fn._getSubmitURL = function() {
    return $instructureEditorBoxList._getEditorBox(this.attr('id'))._submitURL;
  };

  $.fn._getContentURL = function() {
    return $instructureEditorBoxList._getEditorBox(this.attr('id'))._contentURL;
  };

  $.fn._getSelectionOffset = function() {
    var id = this.attr('id');
    var box = $instructureEditorBoxList._getEditor(id).getContainer();
    var boxOffset = $(box).find('iframe').offset();
    var node = $instructureEditorBoxList._getEditor(id).selection.getNode();
    var nodeOffset = $(node).offset();
    var scrollTop = $(box).scrollTop();
    var offset = {
      left: boxOffset.left + nodeOffset.left + 10,
      top: boxOffset.top + nodeOffset.top + 10 - scrollTop
    };
    return offset;
  };

  $.fn._getSelectionNode = function() {
    var id = this.attr('id');
    var box = $instructureEditorBoxList._getEditor(id).getContainer();
    var node = $instructureEditorBoxList._getEditor(id).selection.getNode();
    return node;
  };

  $.fn._getSelectionLink = function() {
    var id = this.attr('id');
    var node = tinyMCE.get(id).selection.getNode();
    while(node.nodeName != 'A' && node.nodeName != 'BODY' && node.parentNode) {
      node = node.parentNode;
    }
    if(node.nodeName == 'A') {
      var href = $(node).attr('href');
      var title = $(node).attr('title');
      if(!title || title == '') {
        title = href;
      }
      var result = {
        url: href,
        title: title
      };
      return result;
    }
    return null;
  };

  $.fn._toggleView = function() {
    var id = this.attr('id');
    tinyMCE.execCommand('mceToggleEditor', false, id);
    this._setContentCode(this._getContentCode());
    // Ensure that keyboard focus doesn't get trapped in the ether.
    this.removeAttr('aria-hidden')
      .filter('textarea:visible')
      .focus();
  };

  $.fn._removeEditor = function() {
    EditorCommands.remove(this, $instructureEditorBoxList)
  };

  $.fn._setContentCode = function(val) {
    var id = this.attr('id');
    var editbox = tinyMCE.get(id)
    $instructureEditorBoxList._getTextArea(id).val(val);
    if(editbox && $.isFunction(editbox.execCommand)) {
      editbox.execCommand('mceSetContent', false, val);
      // the refocusing check fixes a keyboard only nav issue in chrome and
      // safari that causes the focus to become trapped in the html editor
      var refocusing = (typeof(event) != 'undefined') && event.relatedTarget
      if(refocusing) {
        $(event.relatedTarget).focus()
      }
    }
  };

  $.fn._insertHTML = function(html) {
    var id = this.attr('id');
    if($instructureEditorBoxList._getEditor(id).isHidden()) {
      this.replaceSelection(html);
    } else {
      tinyMCE.get(id).execCommand('mceInsertContent', false, html);
    }
  };

  // you probably want to just pass focus: true in your initial options
  $.fn._editorFocus = function() {
    var $element = this,
        id = $element.attr('id'),
        editor = $instructureEditorBoxList._getEditor(id);
    if(!editor ) {
      return false;
    }
    if($instructureEditorBoxList._getEditor(id).isHidden()) {
      $instructureEditorBoxList._getTextArea(id).focus().select();
    } else {
      tinyMCE.execCommand('mceFocus', false, id);
      $.publish('editorBox/focus', $element);
    }
    return true;
  };

  $.fn._linkSelection = function(options) {
    if(typeof(options) == "string") {
      options = {url: options};
    }
    var title = options.title;
    var url = Utils.cleanUrl(options.url || "");
    var classes = options.classes || "";
    var defaultText = options.text || options.title || "Link";
    var target = options.target || null;
    var id = $(this).attr('id');
    if(url.indexOf("@") != -1) {
      options.file = false;
      options.image = false;
    } else if (url.indexOf("/") == -1) {
      title = url;
      url = url.replace(/\s/g, "");
      url = location.href + url;
    }
    if(options.file) {
      classes += "instructure_file_link ";
    }
    if(options.scribdable) {
      classes += "instructure_scribd_file ";
    }
    var link_id = '';
    if(options.kaltura_entry_id && options.kaltura_media_type) {
      link_id = "media_comment_" + options.kaltura_entry_id;
      if(options.kaltura_media_type == 'video') {
        classes += "instructure_video_link ";
      } else {
        classes += "instructure_audio_link ";
      }
    }
    if(options.image) {
      classes += "instructure_image_thumbnail ";
    }
    classes = $.unique(classes.split(/\s+/)).join(" ");
    var selectionText = "";
    if(enableBookmarking && this.data('last_bookmark')) {
      tinyMCE.get(id).selection.moveToBookmark(this.data('last_bookmark'));
    }
    var selection = tinyMCE.get(id).selection;
    var anchor = selection.getNode();
    while(anchor.nodeName !== "A" && anchor.nodeName !== "BODY" && anchor.parentNode) {
      anchor = anchor.parentNode;
    }
    if(anchor.nodeName !== "A") { anchor = null; }

    var selectedContent = options.selectedContent || selection.getContent();
    var selectedContent = decodeString(selectedContent)

    var linkAttrs = {
      target: target || '',
      title: title || '',
      href: url,
      'class': classes,
      id: link_id
    };

    if (options.dataAttributes && options.dataAttributes['preview-alt']) {
      linkAttrs['data-preview-alt'] = options.dataAttributes['preview-alt'];
    }

    if($instructureEditorBoxList._getEditor(id).isHidden()) {
      selectionText = defaultText;
      var $div = $("<div><a/></div>");
      var $a = $div.find("a");
      $a.attr(linkAttrs);
      if (!link_id) {
        $a.removeAttr('id')
      }
      if (!classes) {
        $a.removeAttr('class')
      }
      $a.text(selectionText);
      var link_html = $div.html();
      $(this).replaceSelection(link_html);
    } else if(!selectedContent || selectedContent == "") {
      if(anchor) {
        linkAttrs['data-mce-href'] = url
        linkAttrs['_mce_href'] = url
        $(anchor).attr(linkAttrs);
      } else {
        selectionText = defaultText;
        var $div = $("<div/>");
        $div.append($("<a/>", linkAttrs).text(selectionText));
        tinyMCE.get(id).execCommand('mceInsertContent', false, $div.html());
      }
    } else {
      EditorCommands.insertLink(id, selectedContent, linkAttrs)
    }

    var ed = tinyMCE.get(id);
    var e = ed.selection.getNode();
    if(e.nodeName != 'A') {
      e = $(e).children("a:last")[0];
    }
    if(e) {
      var nodeOffset = {top: e.offsetTop, left: e.offsetLeft};
      var n = e;
      // There's a weird bug here that I can't figure out.  If the editor box is scrolled
      // down and the parent window is scrolled down, it gives different value for the offset
      // (nodeOffset) than if only the editor window is scrolled down.  You scroll down
      // one pixel and it changes the offset by like 60.
      // This is the fix.
      while((n = n.offsetParent) && n.tagName != 'BODY') {
        nodeOffset.top = nodeOffset.top + n.offsetTop || 0;
        nodeOffset.left = nodeOffset.left + n.offsetLeft || 0;
      }
      var box = ed.getContainer();
      var boxOffset = $(box).find('iframe').offset();
      var frameTop = $(ed.dom.doc).find("html").scrollTop() || $(ed.dom.doc).find("body").scrollTop();
      var offset = {
        left: boxOffset.left + nodeOffset.left,
        top: boxOffset.top + nodeOffset.top - frameTop
      };
      $(e).indicate({offset: offset, singleFlash: true, scroll: true, container: $(box).find('iframe')});
    }
  };

});
