/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import I18n from 'i18n!editor'
import $ from 'jquery'
import htmlEscape from '../../str/htmlEscape'
import TinyMCEContentItem from 'tinymce_plugins/instructure_external_tools/TinyMCEContentItem'
import ExternalToolsHelper from 'tinymce_plugins/instructure_external_tools/ExternalToolsHelper'
import iframeAllowances from 'jsx/external_apps/lib/iframeAllowances'
import {send} from 'jsx/shared/rce/RceCommandShim'
import '../../jquery.instructure_misc_helpers'
import 'jqueryui/dialog'
import '../../jquery.instructure_misc_plugins'
import Links from 'tinymce_plugins/instructure_links/links'

  var TRANSLATIONS = {
    embed_from_external_tool: I18n.t('embed_from_external_tool', '"Embed content from External Tool"'),
    more_external_tools: htmlEscape(I18n.t('more_external_tools', "More External Tools"))
  };

  var ExternalToolsPlugin = {
    init: function(ed, url, _INST) {
      Links.initEditor(ed)
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
        // xsslint safeString.identifier iframeAllowancesString
        var dialogHTML = '<div id="external_tool_button_dialog" style="padding: 0; overflow-y: hidden;"/>'
        var iframeAllowancesString = iframeAllowances()
        $dialog = $(dialogHTML)
          .hide()
          .html("<div class='teaser' style='width: 800px; margin-bottom: 10px; display: none;'></div>" +
            '<div class="before_external_content_info_alert screenreader-only" tabindex="0">' +
              '<div class="ic-flash-info">' +
                '<div class="ic-flash__icon" aria-hidden="true">' +
                  '<i class="icon-info"></i>' +
                '</div>' +
                htmlEscape(I18n.t('The following content is partner provided')) +
              '</div>' +
            '</div>' +
            '<form id="external_tool_button_form" method="POST" target="external_tool_launch">' +
              '<input type="hidden" name="editor" value="1" />' +
              '<input id="selection_input" type="hidden" name="selection" />' +
              '<input id="editor_contents_input" type="hidden" name="editor_contents" />' +
            '</form>' +
            "<iframe name='external_tool_launch' src='/images/ajax-loader-medium-444.gif' id='external_tool_button_frame' style='width: 800px; height: " +
            frameHeight +
            "px; border: 0;' allow='" + iframeAllowancesString + "' borderstyle='0' tabindex='0'/>" +
            '<div class="after_external_content_info_alert screenreader-only" tabindex="0">' +
              '<div class="ic-flash-info">' +
                '<div class="ic-flash__icon" aria-hidden="true">' +
                  '<i class="icon-info"></i>' +
                '</div>' +
                htmlEscape(I18n.t('The preceding content is partner provided')) +
              '</div>' +
            '</div>')
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

          const $external_content_info_alerts = $dialog
            .find('.before_external_content_info_alert, .after_external_content_info_alert');

          const $iframe = $dialog.find('iframe');

          $external_content_info_alerts.on('focus', function(e) {
            var iframeWidth = $iframe.outerWidth(true);
            var iframeHeight = $iframe.outerHeight(true);
            $iframe.css('border', '2px solid #008EE2');
            $(this).removeClass('screenreader-only');
            var alertHeight = $(this).outerHeight(true);
            $iframe.css('height', (iframeHeight - alertHeight - 4) + 'px')
              .css('width', (iframeWidth - 4) + 'px');
            $dialog.scrollLeft(0).scrollTop(0)
          });

          $external_content_info_alerts.on('blur', function(e) {
            var iframeWidth = $iframe.outerWidth(true);
            var iframeHeight = $iframe.outerHeight(true);
            var alertHeight = $(this).outerHeight(true);
            $dialog.find('iframe').css('border', 'none');
            $(this).addClass('screenreader-only');
            $iframe.css('height', (iframeHeight + alertHeight) + 'px')
              .css('width', iframeWidth + 'px');
            $dialog.scrollLeft(0).scrollTop(0)
          });
      }

      $(window).unbind("externalContentReady");
      $(window).bind("externalContentReady", function (event, data) {
        var editor = $dialog.data('editor') || ed,
          contentItems = data.contentItems,
          itemLength = contentItems.length,
          codePayload;

        for(var i = 0; i < itemLength; i++){
          codePayload = TinyMCEContentItem.fromJSON(contentItems[i]).codePayload;
          send($("#" + editor.id), 'insert_code', codePayload)
        }
        $dialog.find('iframe').attr('src', 'about:blank');
        $dialog.off("dialogbeforeclose", ExternalToolsPlugin.dialogCancelHandler);
        $dialog.dialog('close')
      });

      $dialog.dialog({
        title: button.name,
        width: (button.width || 800),
        height: (button.height || frameHeight || 400),
        close: () => ExternalToolsHelper.contentItemDialogClose($dialog, ExternalToolsPlugin),
        open: () => ExternalToolsHelper.contentItemDialogOpen(
          button,
          ed,
          ENV.context_asset_string,
          $('#external_tool_button_form')
        )
      });

      $(window).on('beforeunload', ExternalToolsPlugin.beforeUnloadHandler);
      $dialog.on("dialogbeforeclose", ExternalToolsPlugin.dialogCancelHandler);
      $dialog.dialog('close').dialog('open');
      $dialog.triggerHandler('dialogresize')
      $dialog.data('editor', ed);

      return $dialog;
    },
  }





export default ExternalToolsPlugin
