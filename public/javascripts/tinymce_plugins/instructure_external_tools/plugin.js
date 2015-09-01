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
  'jquery.dropdownList',
  'jquery.instructure_misc_helpers',
  'jqueryui/dialog',
  'jquery.instructure_misc_plugins',
  'underscore'
], function(tinymce, I18n, $, htmlEscape, TinyMCEContentItem) {

  var TRANSLATIONS = {
    embed_from_external_tool: I18n.t('embed_from_external_tool', '"Embed content from External Tool"'),
    more_external_tools: htmlEscape(I18n.t('more_external_tools', "More External Tools"))
  };


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
  var ExternalTools = {

    /**
     * build the TinyMCE configuration hash for each
     * LTI button.  Call once for each button to add
     * to the toolbar
     *
     * the "widget" and "btn" classes are what tinymce
     * provides by default and the theme makes use of them,
     * if you don't include them than our custom class
     * overwrites the default classes and all the styles break
     *
     * @param {Hash (representing a button)} button a collection of name, id,
     *   icon_url to use for building the right config for an external plugin
     *
     * @returns {Hash} appropriate configuration for a tinymce addButton call,
     *   complete with title, cmd, image, and classes
     */
    buttonConfig: function(button){
      return {
        title: button.name,
        cmd: 'instructureExternalButton' + button.id,
        image: button.icon_url,
        classes: 'widget btn instructure_external_tool_button'
      };
    },

    /**
     * convert the button clump configuration to
     * an associative array where the key is an image tag
     * with the name and the value is the thing to do
     * when that button gets clicked.  This gives us
     * a decent structure for mapping click events for
     * each dynamically generated button in the button clump
     * list.
     *
     * @param {Array<Hash (representing a button)>} clumpedButtons an array of
     *   button configs, like the ones passed into "buttonConfig"
     *   above as parameters
     *
     * @param {function(Hash)} onClickHandler the function that should get
     *   called when this button gets clicked
     *
     * @returns {Hash<string,function(Hash)>} the hash we can use
     *   for generating a dropdown list in jquery
     */
    clumpedButtonMapping: function(clumpedButtons, onClickHandler){
      return clumpedButtons.reduce(function(items, button){
        var key = "<img src='" + htmlEscape(button.icon_url) +
          "'/>&nbsp;" + htmlEscape(button.name);
        items[key] = function() { onClickHandler(button); };
        return items;
      }, {});
    },


    /**
     * extend the dropdown menu for all the buttons
     * clumped up into the "externalButtonClump", and attach
     * an event to the editor so that whenever you click
     * anywhere else on the editor the dropdown goes away.
     *
     * @param {jQuery Object} target the Dom element we're attaching
     *   this dropdown list to
     * @param {Hash<string,function(Hash)>} buttons the buttons to put
     *   into the dropdown list, typically generated from 'clumpedButtonMapping'
     * @param {tinymce.Editor} editor the relevant editor for this
     *   dropdown list, to whom we will listen for any click events
     *   outside the dropdown menu
     */
    attachClumpedDropdown: function(target, buttons, editor){
      target.dropdownList({ options: buttons });
      editor.on('click', function(e){
        target.dropdownList('hide');
      });
    }

  };

  tinymce.create('tinymce.plugins.InstructureExternalTools', {
    init : function(ed, url) {
      if(!window || !window.INST || !window.INST.editorButtons || !window.INST.editorButtons.length) {
        return
      }
      var $dialog = null;
      var clumpedButtons = [];
      function buttonSelected(button) {
        var frameHeight = Math.max(Math.min($(window).height() - 100, 550), 100);
        if(!$dialog) {
          // xsslint safeString.identifier frameHeight
          $dialog = $('<div id="external_tool_button_dialog" style="padding: 0; overflow-y: hidden;"/>')
            .hide()
            .html("<div class='teaser' style='width: 800px; margin-bottom: 10px; display: none;'></div>" +
                  "<iframe id='external_tool_button_frame' style='width: 800px; height: " + frameHeight +"px; border: 0;' src='/images/ajax-loader-medium-444.gif' borderstyle='0' tabindex='0'/>")
            .appendTo('body')
            .dialog({
              autoOpen: false,
              width: 'auto',
              resizable: true,
              close: function() {
                $dialog.find("iframe").attr('src', '/images/ajax-loader-medium-444.gif');
              },
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
            $("#" + editor.id).editorBox('insert_code', codePayload);
          }
          $dialog.find('iframe').attr('src', 'about:blank');
          $dialog.dialog('close')
        });
        $dialog.dialog('option', 'title', 'Embed content from ' + button.name);
        $dialog.dialog('close')
          .dialog('option', 'width', button.width || 800)
          .dialog('option', 'height', button.height || frameHeight || 400)
          .dialog('open');
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
      }
      for(var idx in INST.editorButtons) {
        var current_button = INST.editorButtons[idx];
        if(INST.editorButtons.length > INST.maxVisibleEditorButtons && idx >= INST.maxVisibleEditorButtons - 1) {
          clumpedButtons.push(current_button);
        } else {
          (function(button) {
            ed.addCommand('instructureExternalButton' + button.id, function() {
              buttonSelected(button);
            });
            ed.addButton('instructure_external_button_' + button.id, ExternalTools.buttonConfig(button));
          })(current_button)
        }
      }
      if(clumpedButtons.length) {
        var handleClick = function(){
          var items = ExternalTools.clumpedButtonMapping(clumpedButtons, buttonSelected);
          ExternalTools.attachClumpedDropdown($("#" + this._id), items, ed);
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

    getInfo : function() {
      return {
        longname : 'InstructureExternalTools',
        author : 'Brian Whitmer',
        authorurl : 'http://www.instructure.com',
        infourl : 'http://www.instructure.com',
        version : tinymce.majorVersion + "." + tinymce.minorVersion
      };
    }
  });

  // Register plugin
  tinymce.PluginManager.add('instructure_external_tools', tinymce.plugins.InstructureExternalTools);

  // Return helpers namespace for unit testing
  return ExternalTools;

});
