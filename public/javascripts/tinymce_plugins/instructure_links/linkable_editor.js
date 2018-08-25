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

import $ from "jquery"
import {send} from 'jsx/shared/rce/RceCommandShim'

  /**
   * This is not yet a complete extraction, but the idea is to continue
   * moving direct interactions with the relevant tinymce editor
   * out of the link plugin itself and into this proxy object.
   *
   * The need first arose in response to an IE11 bug where some state
   * (specifically the currently selected content) needed to be extracted
   * and held onto at the time the link modal is generated, because IE11
   * loses the editor carat on a modal activation.  Rather than
   * use variables with very broad scope in the plugin itself to capture the
   * state at one point and use in another, this hides the temporary
   * persistance inside a kind of decorator.
   *
   * @param {tinymce.Editor} editor the tinymce instance we want
   *   to add links to
   * @param {jquery.Object} $editorEl an optional override for the editor target
   *   that can be found in normal circumstances by calling "getEditor"
   */
  var LinkableEditor = function(editor, $editorEl){

    this.id = editor.id;
    this.selectedContent = editor.selection.getContent();
    this.selectionDetails = {
      node: editor.selection.getNode(),
      range: editor.selection.getRng()
    }
    this.$editorEl = $editorEl;

    /**
     * Builds a jquery object wrapping the target text area for the
     * wrapped tinymce editor. Can be overridden in the constructor with
     * an optional second parameter.
     *
     * @returns {jquery.Object}
     */
    this.getEditor = function(){
      if(this.$editorEl !== undefined){
        return this.$editorEl;
      }
      return $("#" + this.id);
    };

    /**
     * proxies through a call to our jquery extension that puts new link
     * html into an existing tinymce editor.  Specifically useful
     * because of the "selectedContent" and "selectedRange" which are stored
     * at the time the link creation dialog is created (this is important
     * because in IE11 that information is lost as soon as the modal dialog
     * comes up)
     *
     * @param {String} text the interior content for the a tag
     * @param {String} classes any css classes to apply to the new link
     * @param {Object} [dataAttrs] key value pairs for link data attributes
     */
    this.createLink = function(text, classes, dataAttrs){
      send(this.getEditor(), "create_link",{
        url: text,
        classes: classes,
        selectedContent: this.selectedContent,
        dataAttributes: dataAttrs,
        selectionDetails: this.selectionDetails
      });
    };
  };

export default LinkableEditor;
