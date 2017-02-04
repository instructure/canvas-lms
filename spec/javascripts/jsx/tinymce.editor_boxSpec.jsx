/**
 * Copyright (C) 2016 Instructure, Inc.
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
  'tinymce.editor_box_list',
  'tinymce.commands',
  'tinymce.editor_box',
  'compiled/tinymce'
], ($, EditorBoxList, EditorCommands) => {

  let alt, createLinkOpts, editor, node

  QUnit.module('editor box: create_link', {
    setup () {
      alt = 'preview alt text'
      createLinkOpts = {
        title: 'link title',
        url: 'http://instructure.com',
        classes: 'class-a class-b',
        target: '_blank',
        dataAttributes: {
          'preview-alt': alt
        }
      }
      node = document.createElement('span')
      editor = {
        selection: {
          getNode: () => node,
          getContent: () => 'text',
        },
        isHidden: () => false,
        getContainer: () => node,
        dom: {},
        execCommand: this.spy()
      }
      this.stub(tinyMCE, 'get').returns(editor)
      this.stub(EditorBoxList.prototype, '_getEditor').returns(editor)
      this.stub($.fn, 'offset').returns({left: 0, right: 0})
    }
  });

  test('sets preview-alt data attribute when editor is hidden', function () {
    editor.isHidden = () => true
    this.stub($.fn, 'replaceSelection')
    $(node).editorBox('create_link', createLinkOpts)
    const html = $.fn.replaceSelection.firstCall.args[0]
    const elem = document.createElement('div')
    elem.innerHTML = html
    equal(elem.querySelector('a').dataset.previewAlt, alt)
  }); 

  test('sets preview-alt data attribute when cursor is in a link', function () {
    node = document.createElement('a')
    editor.selection.getContent = () => null
    this.spy($.fn, 'attr')
    $(node).editorBox('create_link', createLinkOpts)
    ok($.fn.attr.calledWithMatch({'data-preview-alt': alt}))
  })

  test('sets preview-alt data attribute when cursor is not in a link', function () {
    node = document.createElement('span')
    editor.selection.getContent = () => null
    $(node).editorBox('create_link', createLinkOpts)
    const html = editor.execCommand.firstCall.args[2]
    const elem = document.createElement('div')
    elem.innerHTML = html
    equal(elem.querySelector('a').dataset.previewAlt, alt)
  })

  test('sets preview-alt data attribute with selection', function () {
    this.stub(EditorCommands, 'insertLink')
    $(node).editorBox('create_link', createLinkOpts)
    equal(EditorCommands.insertLink.firstCall.args[2]['data-preview-alt'], alt)
  })
});
