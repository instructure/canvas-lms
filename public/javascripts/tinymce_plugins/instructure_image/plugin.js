/*
 * Copyright (C) 2012 - present Instructure, Inc.
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
import I18n from 'i18n!editor'
import $ from 'jquery'
import htmlEscape from '../../str/htmlEscape'
import 'jqueryui/dialog'

tinymce.create('tinymce.plugins.InstructureImagePlugin', {
  init: function(ed, url) {
    // Register commands
    ed.addCommand('mceInstructureImage', function() {
      var selectedNode = ed.selection.getNode()

      // Internal image object like a flash placeholder
      if (ed.dom.getAttrib(selectedNode, 'class', '').indexOf('mceItem') != -1) return

      require.ensure(
        [],
        function(require) {
          var InsertUpdateImageView = require('compiled/views/tinymce/InsertUpdateImageView')
          new InsertUpdateImageView(ed, selectedNode)
        },
        'initImagePickerAsyncChunk'
      )
    })

    // Register buttons
    ed.addButton('instructure_image', {
      title: htmlEscape(I18n.t('embed_image', 'Embed Image')),
      cmd: 'mceInstructureImage',
      icon: 'image',
      onPostRender: function() {
        // highlight our button when an image is selected
        var btn = this
        ed.on('NodeChange', function(event) {
          btn.active(event.nodeName == 'IMG' && event.className != 'equation_image')
        })
      }
    })
  },

  getInfo: function() {
    return {
      longname: 'Instructure image',
      author: 'Instructure',
      authorurl: 'http://instructure.com',
      infourl: 'http://instructure.com',
      version: '1'
    }
  }
})

// Register plugin
tinymce.PluginManager.add('instructure_image', tinymce.plugins.InstructureImagePlugin)
