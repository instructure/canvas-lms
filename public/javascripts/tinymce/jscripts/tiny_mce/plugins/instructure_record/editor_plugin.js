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
  'jquery',
  'media_comments'
], function($) {

  tinymce.create('tinymce.plugins.InstructureRecord', {
    init : function(ed, url) {
      ed.addCommand('instructureRecord', function() {
        var $editor = $("#" + ed.id);
        $.mediaComment('create', 'any', function(id, mediaType) {
          $editor.editorBox('insert_code', "<a href='/media_objects/" + id + "' class='instructure_inline_media_comment " + (mediaType || "video") + "_comment' id='media_comment_" + id + "'>this is a media comment</a><br>");
          ed.selection.select($(ed.getBody()).find("#media_comment_"+id+" + br")[0]);
          ed.selection.collapse(true);
        })
      });
      ed.addButton('instructure_record', {
        title: 'Record/Upload Media',
        cmd: 'instructureRecord',
        image: url + '/img/record.gif'
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
});

