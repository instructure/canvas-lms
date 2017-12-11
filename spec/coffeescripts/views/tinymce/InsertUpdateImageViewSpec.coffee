#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  'compiled/views/tinymce/InsertUpdateImageView'
  'jsx/shared/rce/RceCommandShim'
], ($, InsertUpdateImageView, RceCommandShim) ->
  fakeEditor = undefined
  moveToBookmarkSpy = undefined

  QUnit.module "InsertUpdateImageView#update",
    setup: ->
      moveToBookmarkSpy = sinon.spy()
      fakeEditor = {
        id: "someId"
        focus: ()->
        dom: {
          createHTML: (()=> return "<a href='#'>stub link html</a>")
        }
        selection: {
          getBookmark: ()->
          moveToBookmark: moveToBookmarkSpy
        }
      }

      sinon.stub(RceCommandShim, 'send')

    teardown: ->
      $("#fixtures").html("")
      RceCommandShim.send.restore()
      $(".ui-dialog").remove()

  test "it uses RceCommandShim to call insert_code", ->
    view = new InsertUpdateImageView(fakeEditor, "<div></div>")
    view.$editor = '$fakeEditor'
    view.update()
    ok RceCommandShim.send.calledWith('$fakeEditor', 'insert_code', view.generateImageHtml())

  test "it updates attributes of existing image if selected node is img", ->
    view = new InsertUpdateImageView(fakeEditor, "<img>")
    img = view.$selectedNode
    view.$editor = '$fakeEditor'
    view.$("[name='image[width]']").val("400")
    view.$("[name='image[height]']").val("300")
    view.$("[name='image[src]']").val("testsrc")
    view.$("[name='image[alt]']").val("testalt")
    view.update()
    equal(img.attr('width'), "400")
    equal(img.attr('height'), "300")
    equal(img.attr('src'), "testsrc")
    equal(img.attr('alt'), "testalt")

  test "it restores caret on update", ->
    view = new InsertUpdateImageView(fakeEditor, "<div></div>")
    view.$editor = '$fakeEditor'
    view.update()
    ok moveToBookmarkSpy.called

  test "it restores caret on close", ->
    view = new InsertUpdateImageView(fakeEditor, "<div></div>")
    view.$editor = '$fakeEditor'
    view.close()
    ok moveToBookmarkSpy.called
