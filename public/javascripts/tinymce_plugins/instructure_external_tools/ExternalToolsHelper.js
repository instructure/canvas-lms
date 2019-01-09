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

import $ from 'jquery'
import htmlEscape from '../../str/htmlEscape'
import '../../jquery.dropdownList'
import '../../jquery.instructure_misc_helpers'
import {processContentItemsForEditor} from '../../../../app/jsx/deep_linking/ContentItemProcessor'

  /**
   * A module for holding helper functions pulled out of the instructure_external_tools/plugin.
   *
   * This should make it easy to seperate and test logic as this evolves
   * without splitting out another module, and since the plugin gets
   * registered with tinymce rather than returned, we can return this
   * object at the end of the module definition as an export for unit testing.
   *
   * @exports
   */

export default {

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
      var config = {
        title: button.name,
        cmd: 'instructureExternalButton' + button.id,
        classes: 'widget btn instructure_external_tool_button'
      };

      if (button.canvas_icon_class) {
        config.icon = 'hack-to-avoid-mce-prefix ' + button.canvas_icon_class;
      } else {
        // default to image
        config.image = button.icon_url;
      }

      return config;
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
     * @param {function(Hash), editor} onClickHandler the function that should get
     *   called when this button gets clicked
     *
     * @returns {Hash<string,function(Hash)>} the hash we can use
     *   for generating a dropdown list in jquery
     */
    clumpedButtonMapping: function(clumpedButtons, ed, onClickHandler){
      return clumpedButtons.reduce(function(items, button){
        var key;

        // added  data-tool-id='"+ button.id +"' to make elements unique when the have the same name
        if (button.canvas_icon_class) {
          key = "<i class='"+ htmlEscape(button.canvas_icon_class) +"' data-tool-id='"+ button.id +"'></i>";
        } else {
          // icon_url is implied
          key = "<img src='"+ htmlEscape(button.icon_url) +"' data-tool-id='"+ button.id +"'/>";
        }
        key += "&nbsp;" + htmlEscape(button.name);
        items[key] = function() { onClickHandler(button, ed); };
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
    },

    contentItemDialogOpen: (button, ed, contextAssetString, $contentItemRequestForm) => {
      let url = $.replaceTags($("#context_external_tool_resource_selection_url").attr('href'), 'id', button.id);
      let asset = ''
      const selection = ed.selection.getContent() || "";
      const contents = ed.getContent() || "";

      if (url === null || typeof url === 'undefined') {
        // if we don't have a url on the page, build one using the current context.
        // url should look like: /courses/2/external_tools/15/resoruce_selection?editor=1
        asset = contextAssetString.split('_');
        url = `/${asset[0]}s/${asset[1]}/external_tools/${button.id}/resource_selection`;
      }

      $contentItemRequestForm.attr('action', url);
      $contentItemRequestForm.find('#editor_contents_input').val(contents);
      $contentItemRequestForm.find('#selection_input').val(selection);
      $contentItemRequestForm.submit();
    },

    contentItemDialogClose: (contentItemDialog, externalToolsPlugin) => {
      $(window).off('beforeunload', externalToolsPlugin.beforeUnloadHandler);
      $(window).unbind("externalContentReady");
      contentItemDialog.dialog('destroy').remove()
    },

    createDeepLinkingListener: (editor, dialogId) => {
      return event => {
        // Only accept messages from the same origin
        if (event.origin === ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN) {
          processContentItemsForEditor(
            event,
            editor,
            dialogId
          )
        }
      }
    }
  };
