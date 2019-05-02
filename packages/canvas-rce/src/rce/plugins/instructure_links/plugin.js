/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import formatMessage from "../../../format-message"
import clickCallback from "./clickCallback"
import bridge from '../../../bridge'
import $ from 'jquery'

const PLUGIN_KEY = 'links'
var keyMap = {};
tinymce.create("tinymce.plugins.InstructureLinksPlugin", {
  init(ed) {
    ed.on('keydown',function(e) {
      keyMap[e.keyCode] = true
      // alt + f7
      if(keyMap[18] && keyMap[118]){
        $('.tox-toolbar-textfield').focus()
        e.preventDefault();
      }
    });
    ed.on('keyup',function(e) {
      keyMap[e.keyCode] = false;
    });
    const isAnchorElement = function (node) {
      return node.nodeName.toLowerCase() === 'a' && node.href;
    };

    const isSelected = function () {
      return !ed.selection.isCollapsed()
    };

    const getAnchorElement = function () {
      const node = ed.selection.getNode();
      return isAnchorElement(node) ? node : null;
    };

    ed.ui.registry.addContextForm('link-form', {
      launch: {
        type: 'contextformtogglebutton',
        icon: 'link'
      },
      label: formatMessage('Link'),
      predicate: (node) => {
        return isAnchorElement(node) || isSelected()
      },
      initValue: function () {
        const elm = getAnchorElement();
        return elm ? elm.href : '';
      },
      commands: [
        {
          type: 'contextformtogglebutton',
          icon: 'link',
          tooltip: formatMessage('Link'),
          primary: true,
          onSetup: function (buttonApi) {
            buttonApi.setActive(!!getAnchorElement());
            const nodeChangeHandler = function () {
              buttonApi.setActive(!ed.readonly && !!getAnchorElement());
            };
            ed.on('nodechange', nodeChangeHandler);
            return function () {
              ed.off('nodechange', nodeChangeHandler);
            }
          },
          onAction: function (formApi) {
            const value = formApi.getValue();
            ed.execCommand('mceInsertLink', false, {href: value});
            formApi.hide();
          }
        },
        {
          type: 'contextformtogglebutton',
          icon: 'unlink',
          tooltip: formatMessage('Remove link'),
          active: false,
          onAction: function (formApi) {
            ed.execCommand('unlink');
            formApi.hide();
          }
        }
      ]
    });

    // Register commands
    ed.addCommand(
      "instructureLinks",
      clickCallback.bind(this, ed, document)
    );

    // Register button
    ed.ui.registry.addMenuButton("instructure_links", {
      tooltip: formatMessage('Links'),
      icon: "link",
      fetch(callback) {
        const items = [
          {
            type: 'menuitem',
            text: formatMessage('External Links'),
            onAction: () => {
              ed.execCommand('mceLink');
            }
          },
          {
            type: 'menuitem',
            text: formatMessage('Course Links'),
            onAction() {
              ed.focus(true) // activate the editor without changing focus
              bridge.showTrayForPlugin(PLUGIN_KEY)
            }
          }
        ]
        callback(items)
      }
    });
  }
});

// Register plugin
tinymce.PluginManager.add(
  "instructure_links",
  tinymce.plugins.InstructureLinksPlugin
);
