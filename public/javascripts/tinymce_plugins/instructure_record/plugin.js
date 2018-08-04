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
import mediaEditorLoader from 'tinymce_plugins/instructure_record/mediaEditorLoader'
import I18n from 'i18n!editor'

  tinymce.create('tinymce.plugins.InstructureRecord', {
    init : function(ed, url) {
      ed.addCommand('instructureRecord', mediaEditorLoader.insertEditor.bind(mediaEditorLoader, ed));
      ed.addButton('instructure_record', {
        title: I18n.t('Record/Upload Media'),
        cmd: 'instructureRecord',
        icon: 'video icon-video'
      });
    },

    getInfo : function() {
      return {
        longname : 'InstructureRecord',
        author : 'Brian Whitmer',
        authorurl : 'http://www.instructure.com',
        infourl : 'http://www.instructure.com',
        version : tinymce.majorVersion + "." + tinymce.minorVersion
      };
    }
  });

  // Register plugin
  tinymce.PluginManager.add('instructure_record', tinymce.plugins.InstructureRecord);
