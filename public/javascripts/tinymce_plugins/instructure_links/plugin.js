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

import tinymce from 'compiled/editor/stocktiny'
import Links from 'tinymce_plugins/instructure_links/links'
import I18n from 'i18n!editor'

  tinymce.create('tinymce.plugins.InstructureLinks', {
    init : function(ed, url) {
      ed.addCommand('instructureLinks', Links.renderDialog.bind(null, ed));

      ed.addButton('instructure_links', {
        title: I18n.t('Link to URL'),
        cmd: 'instructureLinks',
        icon: 'link',
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

      Links.initEditor(ed)
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

