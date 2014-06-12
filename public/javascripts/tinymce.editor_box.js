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
  'compiled/editor/editorAccessibility', /* editorAccessibility */
  //'compiled/tinymce', // required, but the bundles that ACTUALLY use
                        // tiny can require it themselves or else we have
                        // build problems
  'INST', // for IE detection; need to handle links in a special way
  'jqueryui/draggable' /* /\.draggable/ */,
  'jquery.instructure_misc_plugins' /* /\.indicate/ */,
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */,
  'vendor/jquery.ba-tinypubsub',
  'vendor/scribd.view' /* scribd */
], function(I18nObj, $, EditorAccessibility, INST) {

  var enableBookmarking = !!INST.browser.ie;
  $(document).ready(function() {
    enableBookmarking = !!INST.browser.ie;
  });

  function EditorBoxList() {
    this._textareas = {};
    this._editors = {};
    this._editor_boxes = {};
  };

  $.extend(EditorBoxList.prototype, {
    _addEditorBox: function(id, box) {
      $.publish('editorBox/add', id, box);
      this._editor_boxes[id] = box;
      this._editors[id] = tinyMCE.get(id);
      this._textareas[id] = $("textarea#" + id);
    },
    _removeEditorBox: function(id) {
      delete this._editor_boxes[id];
      delete this._editors[id];
      delete this._textareas[id];
      $.publish('editorBox/remove', id);
      if ($.isEmptyObject(this._editors)) $.publish('editorBox/removeAll');
    },
    _getTextArea: function(id) {
      if(!this._textareas[id]) {
        this._textareas[id] = $("textarea#" + id);
      }
      return this._textareas[id];
    },
    _getEditor: function(id) {
      if(!this._editors[id]) {
        this._editors[id] = tinyMCE.get(id);
      }
      return this._editors[id];
    },
    _getEditorBox: function(id) {
      return this._editor_boxes[id];
    }
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
    var instructure_buttons = ",instructure_image,instructure_equation";
    for(var idx in INST.editorButtons) {
      // maxVisibleEditorButtons should be the max number of external tool buttons
      // that are visible, INCLUDING the catchall "more external tools" button that
      // will appear if there are too many to show at once.
      if(INST.editorButtons.length <= INST.maxVisibleEditorButtons || idx < INST.maxVisibleEditorButtons - 1) {
        instructure_buttons = instructure_buttons + ",instructure_external_button_" + INST.editorButtons[idx].id;
      } else if(!instructure_buttons.match(/instructure_external_button_clump/)) {
        instructure_buttons = instructure_buttons + ",instructure_external_button_clump";
      }
    }
    if(INST && INST.allowMediaComments && (INST.kalturaSettings && !INST.kalturaSettings.hide_rte_button)) {
      instructure_buttons = instructure_buttons + ",instructure_record";
    }
    var equella_button = INST && INST.equellaEnabled ? ",instructure_equella" : "";
    instructure_buttons = instructure_buttons + equella_button;

    var buttons1 = "bold,italic,underline,forecolor,backcolor,removeformat,justifyleft,justifycenter,justifyright,bullist,outdent,indent,sup,sub,numlist,table,instructure_links,unlink" + instructure_buttons + ",fontsizeselect,formatselect";
    var buttons2 = "";
    var buttons3 = "";

    if (width < 359 && width > 0) {
      buttons1 = "bold,italic,underline,forecolor,backcolor,removeformat,justifyleft,justifycenter,justifyright";
      buttons2 = "outdent,indent,sup,sub,bullist,numlist,table,instructure_links,unlink" + instructure_buttons;
      buttons3 = "fontsizeselect,formatselect";
    } else if (width < 600) {
      buttons1 = "bold,italic,underline,forecolor,backcolor,removeformat,justifyleft,justifycenter,justifyright,outdent,indent,sup,sub,bullist,numlist";
      buttons2 = "table,instructure_links,unlink" + instructure_buttons + ",fontsizeselect,formatselect";
    }

    var editor_css = "/javascripts/tinymce/jscripts/tiny_mce/themes/advanced/skins/default/ui.css,/stylesheets_compiled/legacy_normal_contrast/tiny_like_ck_with_external_tools.css";

    var tinyOptions = $.extend({
      mode : "exact",
      elements: id,
      theme : "advanced",
      plugins: "autolink,instructure_external_tools,instructure_contextmenu,instructure_links," +
               "instructure_embed,instructure_image,instructure_equation,instructure_record,instructure_equella," +
               "media,paste,table,inlinepopups",
      dialog_type: 'modal',
      language_load: false,
      relative_urls: false,
      remove_script_host: true,
      theme_advanced_buttons1: buttons1,
      theme_advanced_toolbar_location : "top",
      theme_advanced_toolbar_align : "center",
      theme_advanced_buttons2: buttons2,
      theme_advanced_buttons3: buttons3,

      theme_advanced_resize_horizontal : false,
      theme_advanced_resizing : true,
      theme_advanced_blockformats : "p,h2,h3,h4,pre",
      theme_advanced_more_colors: false,
      extended_valid_elements : "iframe[src|width|height|name|align|style|class|sandbox]",
      content_css: "/stylesheets_compiled/legacy_normal_contrast/instructure_style.css,/stylesheets_compiled/legacy_normal_contrast/tinymce.editor_box.css",
      editor_css: editor_css,
      auto_focus: options.focus ? id : null,

      onchange_callback: function(e) {
        $("#" + id).trigger('change');
      },

      setup : function(ed) {
        var $editor = $("#" + ed.editorId);
        var focus = function() {
          $(document).triggerHandler('editor_box_focus', $editor);
          $.publish('editorBox/focus', $editor);
        };
        
        // Make shift+tab take the user to the previous focusable element in the DOM.
        var focusPrevious = function (ed, event) {
          if (event.keyCode == 9 && event.shiftKey) {
            var $cur = $(ed.getContainer());
            while (true) {
              // When jQuery is upgraded to 1.8+, use .addBack(':tabbable') instead of andSelf().filter(...)
              if ($cur.prevAll().find(':tabbable').andSelf().filter(':tabbable').last().focus().length) {
                return false;
              }
              $cur = $cur.parent();
              if (!$cur || !$cur.length || $cur.is(document)) {
                return false;
              }
            }
          } else {
            return true;
          }
        };
        
        ed.onClick.add(focus);
        ed.onKeyPress.add(focus);
        ed.onKeyUp.add(focusPrevious);
        ed.onActivate.add(focus);
        ed.onEvent.add(function() {
          if(enableBookmarking && ed.selection) {
            $textarea.data('last_bookmark', ed.selection.getBookmark(1));
          }
        });

        ed.onInit.add(function(){
          new EditorAccessibility(ed).accessiblize();
        });

        ed.onInit.add(function(){
          $(window).triggerHandler("resize");

          // this is a hack so that when you drag an image from the wikiSidebar to the editor that it doesn't
          // try to embed the thumbnail but rather the full size version of the image.
          // so basically, to document why and how this works: in wiki_sidebar.js we add the
          // _mce_src="http://path/to/the/fullsize/image" to the images whose src="path/to/thumbnail/of/image/"
          // what this does is check to see if some DOM node that got inserted into the editor has the attribute _mce_src
          // and if it does, use that instead.
          $(ed.contentDocument).bind("DOMNodeInserted", function(e){
            var target = e.target,
                mceSrc;
            if (target.nodeType === 1 && target.nodeName === 'IMG'  && (mceSrc = $(target).data('url')) ) {
              $(target).attr('src', tinyMCE.activeEditor.documentBaseURI.toAbsolute(mceSrc));
            }
          });

          // tiny sets a focusout event handler, which only IE supports
          // (Chrome/Safari/Opera support DOMFocusOut, FF supports neither)
          // we attach a blur event that does the same thing (which in turn
          // ensures the change callback fires)
          // this fixes FF's broken behavior (http://www.tinymce.com/develop/bugtracker_view.php?id=4004 )
          // as well as an issue in Safari where tiny didn't register some
          // change events if the previously focused element was a numerical
          // quiz input (something to do with changing its value in a change
          // handler)
          if (!('onfocusout' in ed.contentWindow)) {
            $(ed.contentWindow).blur(function(e) {
              if (!ed.removed && ed.undoManager.typing) {
                ed.undoManager.typing = false;
                ed.undoManager.add();
              }
            });
          }
        });
      }
    }, options.tinyOptions || {});

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
      if(tinyMCE && tinyMCE.getInstanceById(id)) {
        content = tinyMCE.getInstanceById(id).getContent();
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
    this._setContentCode(this._getContentCode());
    tinyMCE.execCommand('mceToggleEditor', false, id);
    // Ensure that keyboard focus doesn't get trapped in the ether.
    this.removeAttr('aria-hidden')
      .filter('textarea:visible')
      .focus();
  };

  $.fn._removeEditor = function() {
    var id = this.attr('id');
    this.data('rich_text', false);
    if(tinyMCE && tinyMCE.execCommand) {
      tinyMCE.execCommand('mceRemoveControl', false, id);
      $instructureEditorBoxList._removeEditorBox(id);
    }
  };

  $.fn._setContentCode = function(val) {
    var id = this.attr('id');
    $instructureEditorBoxList._getTextArea(id).val(val);
    if(tinyMCE.get(id) && $.isFunction(tinyMCE.get(id).execCommand)) {
      tinyMCE.get(id).execCommand('mceSetContent', false, val);
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
    var url = options.url || "";
    if(url.match(/@/) && !url.match(/\//) && !url.match(/^mailto:/)) {
      url = "mailto:" + url;
    } else if(!url.match(/^\w+:\/\//) && !url.match(/^mailto:/) && !url.match(/^\//)) {
      url = "http://" + url;
    }
    var classes = options.classes || "";
    var defaultText = options.text || options.title || "Link";
    var target = options.target || null;
    var id = $(this).attr('id');
    if(url.indexOf("@") != -1) {
      options.file = false;
      options.image = false;
      if(url.indexOf("mailto:") != 0) {
        url = "mailto:" + url;
      }
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
    while(anchor.nodeName != 'A' && anchor.nodeName != 'BODY' && anchor.parentNode) {
      anchor = anchor.parentNode;
    }
    if(anchor.nodeName != 'A') { anchor = null; }

    var selectedContent = selection.getContent();
    if($instructureEditorBoxList._getEditor(id).isHidden()) {
      selectionText = defaultText;
      var $div = $("<div><a/></div>");
      $div.find("a")
        [link_id ? 'attr' : 'removeAttr']('id', link_id).attr({
          title: title,
          href: url,
          target: target
        })
        [classes ? 'attr' : 'removeAttr']('class', classes)
        .text(selectionText);
      var link_html = $div.html();
      $(this).replaceSelection(link_html);
    } else if(!selectedContent || selectedContent == "") {
      if(anchor) {
        $(anchor).attr({
          href: url,
          'data-mce-href': url,
          '_mce_href': url,
          title: title || '',
          id: link_id,
          'class': classes,
          target: target
        });
      } else {
        selectionText = defaultText;
        var $div = $("<div/>");
        $div.append($("<a/>", {id: link_id, target: target, title: title, href: url, 'class': classes}).text(selectionText));
        tinyMCE.get(id).execCommand('mceInsertContent', false, $div.html());
      }
    } else {
      tinyMCE.get(id).execCommand('mceInsertLink', false, {target: (target || ''), title: (title || ''), href: url, 'class': classes, 'id': link_id});
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
