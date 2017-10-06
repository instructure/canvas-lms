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
import {send} from 'jsx/shared/rce/RceCommandShim'
import '../../media_comments'

  var mediaEditorLoader = {
    insertCode: function(ed, mediaCommentId, mediaType, title){
      var $editor = $("#" + ed.id);
      var linkCode = this.makeLinkHtml(mediaCommentId, mediaType, title)
      send($editor, 'insert_code', linkCode);
    },

    makeLinkHtml: function(mediaCommentId, mediaType, title) {
      return $('<a />')
                 .attr({href:`/media_objects/${htmlEscape(mediaCommentId)}`})
                 .addClass('instructure_inline_media_comment')
                 .addClass(`${htmlEscape(mediaType || 'video')}_comment`)
                 .attr({id:`media_comment_${htmlEscape(mediaCommentId)}`})
                 .attr({'data-alt':htmlEscape(title)})
                 .text('this is a media comment')[0].outerHTML
    },

    getComment: function(ed, mediaCommentId){
      return $(ed.getBody()).find("#media_comment_"+mediaCommentId+" + br")[0];
    },

    collapseMediaComment: function(ed, mediaCommentId){
      var commentDiv = this.getComment(ed)
      ed.selection.select(commentDiv);
      ed.selection.collapse(true);
    },

    commentCreatedCallback: function(ed, mediaCommentId, mediaType, title) {
      this.insertCode(ed, mediaCommentId, mediaType, title)
      this.collapseMediaComment(ed, mediaCommentId)
    },

    insertEditor: function(ed){
      $.mediaComment('create', 'any', this.commentCreatedCallback.bind(this, ed))
    }
  }

export default mediaEditorLoader;
