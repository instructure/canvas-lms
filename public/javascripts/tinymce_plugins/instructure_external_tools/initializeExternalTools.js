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
  'i18n!editor',
  'jquery',
  'str/htmlEscape',
  'tinymce_plugins/instructure_external_tools/TinyMCEContentItem',
  'tinymce_plugins/instructure_external_tools/ExternalToolsHelper',
  'jsx/shared/rce/RceCommandShim',
  'jquery.instructure_misc_helpers',
  'jqueryui/dialog',
  'jquery.instructure_misc_plugins'
], function(tinymce, I18n, $, htmlEscape,
            TinyMCEContentItem, ExternalToolsHelper, RceCommandShim) {

  var TRANSLATIONS = {
    embed_from_external_tool: I18n.t('embed_from_external_tool', '"Embed content from External Tool"'),
    more_external_tools: htmlEscape(I18n.t('more_external_tools', "More External Tools"))
  };

  var ExternalToolsPlugin = {
    init: function(ed, url, _INST) {
      if(!_INST || !_INST.editorButtons || !_INST.editorButtons.length) {
        return
      }
      var clumpedButtons = [];
      for (var idx = 0; _INST.editorButtons && (idx < _INST.editorButtons.length); idx++) {
        var current_button = _INST.editorButtons[idx];
        if(_INST.editorButtons.length > _INST.maxVisibleEditorButtons && idx >= _INST.maxVisibleEditorButtons - 1) {
          clumpedButtons.push(current_button);
        } else {
          (function(button) {
            ed.addCommand('instructureExternalButton' + button.id, function() {
              ExternalToolsPlugin.buttonSelected(button, ed);
            });
            ed.addButton('instructure_external_button_' + button.id, ExternalToolsHelper.buttonConfig(button));
          })(current_button)
        }
      }
      if(clumpedButtons.length) {
        var handleClick = function(){
          var items = ExternalToolsHelper.clumpedButtonMapping(clumpedButtons, ed, ExternalToolsPlugin.buttonSelected);
          ExternalToolsHelper.attachClumpedDropdown($("#" + this._id), items, ed);
        }

        ed.addButton('instructure_external_button_clump', {
          title: TRANSLATIONS.more_external_tools,
          image: '/images/downtick.png',
          onkeyup: function(event){
            if (event.keyCode === 32 || event.keyCode === 13) {
              event.stopPropagation()
              handleClick.call(this)
            }
          },
          onclick: handleClick
        })
      }
    },
    beforeUnloadHandler: function(e) {
      return (e.returnValue = I18n.t("Changes you made may not be saved."));
    },
    dialogCancelHandler: function(event, ui) {
      var r = confirm(I18n.t("Are you sure you want to cancel? Changes you made may not be saved."));
      if (r == false){
        event.preventDefault();
      }
    },
    buttonSelected: function(button, ed) {
      var $dialog = $('external_tool_button_dialog')
      var frameHeight = Math.max(Math.min($(window).height() - 100, 550), 100);
      if(!$dialog.length) {
        // xsslint safeString.identifier frameHeight
        var dialogHTML = '<div id="external_tool_button_dialog" style="padding: 0; overflow-y: hidden;"/>'
        $dialog = $(dialogHTML)
          .hide()
          .html("<div class='teaser' style='width: 800px; margin-bottom: 10px; display: none;'></div>" +
            "<iframe id='external_tool_button_frame' style='width: 800px; height: " + frameHeight +"px; border: 0;' src='/images/ajax-loader-medium-444.gif' borderstyle='0' tabindex='0'/>")
          .appendTo('body')
          .dialog({
            autoOpen: false,
            width: 'auto',
            resizable: true,
            title: TRANSLATIONS.embed_from_external_tool
          })
          .bind('dialogresize', function() {
            $(this).find('iframe').add('.fix_for_resizing_over_iframe').height($(this).height()).width($(this).width());
          })
          .bind('dialogresizestop', function() {
            $(".fix_for_resizing_over_iframe").remove();
          })
          .bind('dialogresizestart', function() {
            $(this).find('iframe').each(function(){
              $('<div class="fix_for_resizing_over_iframe" style="background: #fff;"></div>')
                .css({
                  width: this.offsetWidth+"px", height: this.offsetHeight+"px",
                  position: "absolute", opacity: "0.001", zIndex: 10000000
                })
                .css($(this).offset())
                .appendTo("body");
            });
          })
      }

      $(window).unbind("externalContentReady");
      $(window).bind("externalContentReady", function (event, data) {
        var editor = $dialog.data('editor') || ed,
          contentItems = data.contentItems,
          itemLength = contentItems.length,
          codePayload;

        for(var i = 0; i < itemLength; i++){
          codePayload = TinyMCEContentItem.fromJSON(contentItems[i]).codePayload;
          RceCommandShim.send($("#" + editor.id), 'insert_code', codePayload)
        }
        $dialog.find('iframe').attr('src', 'about:blank');
        $dialog.off("dialogbeforeclose", ExternalToolsPlugin.dialogCancelHandler);
        $dialog.dialog('close')
      });
      $dialog.dialog({
        title: I18n.t("Embed content from %{name}", {name: button.name}),
        width: (button.width || 800),
        height: (button.height || frameHeight || 400),
        close: function(){
          $dialog.find("iframe").attr('src', '/images/ajax-loader-medium-444.gif');
          $(window).off('beforeunload', ExternalToolsPlugin.beforeUnloadHandler);
          $(window).unbind("externalContentReady");
        }
      });
      $(window).on('beforeunload', ExternalToolsPlugin.beforeUnloadHandler);
      $dialog.on("dialogbeforeclose", ExternalToolsPlugin.dialogCancelHandler);
      $dialog.dialog('close').dialog('open');
      $dialog.triggerHandler('dialogresize')
      $dialog.data('editor', ed);
      var url = $.replaceTags($("#context_external_tool_resource_selection_url").attr('href'), 'id', button.id);
      if (url === null || typeof url === 'undefined') {
        // if we don't have a url on the page, build one using the current context.
        // url should look like: /courses/2/external_tools/15/resoruce_selection?editor=1
        var asset = ENV.context_asset_string.split('_');
        url = '/' + asset[0] + 's/' + asset[1] + '/external_tools/' + button.id + '/resource_selection?editor=1';
      }
      var selection = ed.selection.getContent() || "";
      url += (url.indexOf('?') > -1 ? '&' : '?') + "selection=" + encodeURIComponent(selection)
      $dialog.find("iframe").attr('src', url);
      return $dialog;
    },
  }





  return ExternalToolsPlugin
});
