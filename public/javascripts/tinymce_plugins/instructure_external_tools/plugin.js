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
  'tinymce_plugins/instructure_external_tools/initializeExternalTools',
  'tinymce_plugins/instructure_external_tools/ExternalToolsHelper',
  'INST'
], function(tinymce, initializeExternalTools, ExternalToolsHelper, INST) {

  tinymce.create('tinymce.plugins.InstructureExternalTools', {
    init : function(ed, url){
      return initializeExternalTools.init(ed, url, INST)
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

  return tinymce;
});
