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
// xsslint safeString.identifier frameHeight teaser

define([
  'compiled/editor/stocktiny',
  'jquery',
  'tinymce_plugins/instructure_equella/initializeEquella',
  'jqueryui/dialog'
], function(tinymce, $, initializeEquella) {

  tinymce.create('tinymce.plugins.InstructureEquella', {
    init : function(ed, url) {
      ed.addCommand('instructureEquella', function () {
        initializeEquella(ed)
      })

      ed.addButton('instructure_equella', {
        title: 'Insert Equella Links',
        cmd: 'instructureEquella',
        icon: 'equella icon-equella'
      });
    },

    getInfo : function() {
      return {
        longname : 'InstructureEquella',
        author : 'Brian Whitmer',
        authorurl : 'http://www.instructure.com',
        infourl : 'http://www.instructure.com',
        version : tinymce.majorVersion + "." + tinymce.minorVersion
      };
    }
  });

  // Register plugin
  tinymce.PluginManager.add('instructure_equella', tinymce.plugins.InstructureEquella);
});

