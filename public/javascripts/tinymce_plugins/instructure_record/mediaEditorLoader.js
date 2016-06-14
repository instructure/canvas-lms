/**
 * Copyright (C) 2015 Instructure, Inc.
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
  'str/htmlEscape',
  'jsx/shared/rce/callOnRCE',
  'media_comments'
], function($, htmlEscape, callOnRCE) {

  var mediaEditorLoader = {
    callOnRCE: callOnRCE,
    insertCode: function(ed, mediaCommentId, mediaType){
      var $editor = $("#" + ed.id);
      var linkCode = this.makeLinkHtml(mediaCommentId, mediaType)
      this.callOnRCE($editor, 'insert_code', linkCode);
    },

    makeLinkHtml: function(mediaCommentId, mediaType) {
      return "<a href='/media_objects/" +
        htmlEscape(mediaCommentId) +
        "' class='instructure_inline_media_comment " +
        htmlEscape(mediaType || "video") +
        "_comment' id='media_comment_" +
        htmlEscape(mediaCommentId) +
        "'>this is a media comment</a><br>";
    },

    getComment: function(ed, mediaCommentId){
      return $(ed.getBody()).find("#media_comment_"+mediaCommentId+" + br")[0];
    },

    collapseMediaComment: function(ed, mediaCommentId){
      var commentDiv = this.getComment(ed)
      ed.selection.select(commentDiv);
      ed.selection.collapse(true);
    },

    commentCreatedCallback: function(ed, mediaCommentId, mediaType) {
      this.insertCode(ed, mediaCommentId, mediaType)
      this.collapseMediaComment(ed, mediaCommentId)
    },

    insertEditor: function(ed){
      $.mediaComment('create', 'any', this.commentCreatedCallback.bind(this, ed))
    }
  }

  return mediaEditorLoader;
});
