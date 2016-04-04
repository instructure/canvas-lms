define([
  'jquery',
  'compiled/editor/editorAccessibility',
  'INST'
], function($, EditorAccessibility, INST){
  return function (tinymce, autoFocus, enableBookmarkingOverride) {

    if (enableBookmarkingOverride == undefined) {
      var enableBookmarking = !!INST.browser.ie;
    } else {
      var enableBookmarking = enableBookmarkingOverride;
    }

    return {
      auto_focus: autoFocus,
      setup : function(ed) {
        var $editor = $("#" + ed.id);
        var focus = function() {
          $editor.triggerHandler('editor_box_focus');
        };

        ed.on('click', focus);
        ed.on('keypress', focus);

        // KeyboardShortcuts.coffee needs to listen to events
        // fired from inside the editor, so we pass out
        // keyup events to the document
        ed.on('keyup', function(e){
          $(document).trigger("editorKeyUp", [e]);
        });

        ed.on('activate', focus);

        ed.on('change', function() {
          $editor.trigger('change');
        });

        // no equivalent of "onEvent" in tinymce4
        ed.on('keyup keydown click mousedown', function() {
          if(enableBookmarking && ed.selection) {
            $textarea.data('last_bookmark', ed.selection.getBookmark(1));
          }
        });

        ed.on('init', function(){
          new EditorAccessibility(ed).accessiblize();
        });

        ed.on('init', function(){
          $(window).triggerHandler("resize");

          // this is a hack so that when you drag an image from the sidebar to the editor that it doesn't
          // try to embed the thumbnail but rather the full size version of the image.
          // so basically, to document why and how this works: in wiki_sidebar.js we add the
          // _mce_src="http://path/to/the/fullsize/image" to the images whose src="path/to/thumbnail/of/image/"
          // what this does is check to see if some DOM node that got inserted into the editor has the attribute _mce_src
          // and if it does, use that instead.
          $(ed.contentDocument).bind("DOMNodeInserted", function(e){
            var target = e.target,
                mceSrc;
            if (target.nodeType === 1 && target.nodeName === 'IMG'  && (mceSrc = $(target).data('url')) ) {
              $(target).attr('src', tinymce.activeEditor.documentBaseURI.toAbsolute(mceSrc));
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
      } // function setup()
    }
  };
});
