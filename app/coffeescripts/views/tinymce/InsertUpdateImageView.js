//
// Copyright (C) 2012 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import I18n from 'i18n!editor'
import $ from 'jquery'
import _ from 'underscore'
import React from 'react'
import ReactDOM from 'react-dom'
import htmlEscape from 'str/htmlEscape'
import FileBrowser from 'jsx/shared/rce/FileBrowser'
import DialogBaseView from '../DialogBaseView'
import template from 'jst/tinymce/InsertUpdateImageView'
import { send } from 'jsx/shared/rce/RceCommandShim'
import FindFlickrImageView from '../FindFlickrImageView'

export default class InsertUpdateImageView extends DialogBaseView {
  toJSON() {
    return {show_quiz_warning: ENV.SHOW_QUIZ_ALT_TEXT_WARNING}
  }

  initialize(editor, selectedNode) {
    this.update = this.update.bind(this)
    this.setSelectedImage = this.setSelectedImage.bind(this)
    this.constrainProportions = this.constrainProportions.bind(this)
    this.onFileLinkClick = this.onFileLinkClick.bind(this)
    this.editor = editor
    this.$editor = $(`#${this.editor.id}`)
    this.prevSelection = this.editor.selection.getBookmark()
    this.$selectedNode = $(selectedNode)
    super.initialize(...arguments)
    this.render()
    this.show()
    this.dialog
      .parent()
      .find('.ui-dialog-titlebar-close')
      .click(() => this.restoreCaret())
    if (this.$selectedNode.prop('nodeName') === 'IMG') {
      return this.setSelectedImage({
        src: this.$selectedNode.attr('src'),
        alt: this.$selectedNode.attr('alt'),
        width: this.$selectedNode.width(),
        height: this.$selectedNode.height(),
        'data-decorative': this.$selectedNode.attr('data-decorative')
      })
    }
  }

  afterRender() {
    this.$('.imageSourceTabs').tabs()
  }

  onTabsshow(event, ui) {
    const loadTab = fn => {
      if (this[`${ui.panel.id}IsLoaded`]) return
      this[`${ui.panel.id}IsLoaded`] = true
      const loadingDfd = $.Deferred()
      $(ui.panel).disableWhileLoading(loadingDfd)
      fn(loadingDfd.resolve)
    }
    switch (ui.panel.id) {
      case 'tabUploaded':
        loadTab(done => {
          ReactDOM.render(
            <FileBrowser allowUpload={true}
                         contentTypes={["image/*"]}
                         selectFile={this.setSelectedImage}
                         useContextAssets={true} />,
            this.$el[0].querySelector('#tabUploaded'),
            done
          )
        })
        break;
      case 'tabFlickr':
        loadTab(done => {
          new FindFlickrImageView().render().$el.appendTo(ui.panel)
          done()
        })
        break;
    }
  }

  setAspectRatio() {
    const width = Number(this.$("[name='image[width]']").val())
    const height = Number(this.$("[name='image[height]']").val())
    if (width && height) {
      return (this.aspectRatio = width / height)
    } else {
      delete this.aspectRatio
    }
  }

  constrainProportions(event) {
    const val = Number($(event.target).val())
    if (this.aspectRatio && (val || val === 0)) {
      if ($(event.target).is('[name="image[height]"]')) {
        this.$('[name="image[width]"]').val(Math.round(val * this.aspectRatio))
      } else {
        this.$('[name="image[height]"]').val(Math.round(val / this.aspectRatio))
      }
    }
  }

  setSelectedImage(attributes = {}) {
    // set given attributes immediately; update width and height after image loads
    let value
    for (var key in attributes) {
      value = attributes[key]
      this.$(`[name='image[${key}]']`).val(value)
    }
    const dfd = $.Deferred()
    const onLoad = ({target: img}) => {
      const newAttributes = _.defaults(attributes, {
        width: img.width,
        height: img.height
      })
      for (key in newAttributes) {
        value = newAttributes[key]
        if (this.$(`[name='image[${key}]']`).attr('type') === 'checkbox') {
          this.$(`[name='image[${key}]']`).attr('checked', !!value)
        } else {
          this.$(`[name='image[${key}]']`).val(value)
        }
      }
      if (newAttributes['data-decorative']) {
        this.$("[name='image[alt]']").attr('disabled', true)
      }
      this.setAspectRatio()
      dfd.resolve(newAttributes)
    }
    const onError = ({target: _img}) => {
      const newAttributes = {
        width: '',
        height: ''
      }

      for (key in newAttributes) {
        value = newAttributes[key]
        this.$(`[name='image[${key}]']`).val(value)
      }
    }
    this.$img = $('<img>', attributes)
      .load(onLoad)
      .error(onError)
    return dfd
  }

  getAttributes() {
    let val
    const res = {}
    for (var key of ['width', 'height']) {
      val = Number(this.$(`[name='image[${key}]']`).val())
      if (val && val > 0) res[key] = val
    }
    for (key of ['src', 'alt']) {
      val = this.$(`[name='image[${key}]']`).val()
      if (val) res[key] = val
    }
    if (this.$("[name='image[data-decorative]']").is(':checked')) {
      res['alt'] = ''
      res['data-decorative'] = true
    }
    res['data-mce-src'] = res.src
    return res
  }

  onFileLinkClick(event) {
    event.preventDefault()
    this.$('.active')
      .removeClass('active')
      .parent()
      .removeAttr('aria-selected')
    const $a = $(event.currentTarget).addClass('active')
    $a.parent().attr('aria-selected', true)
    this.flickr_link = $a.attr('data-linkto')
    this.setSelectedImage({
      src: $a.attr('data-fullsize'),
      alt: $a.attr('title')
    })
    this.$("[name='image[alt]']").focus()
  }

  onFileLinkDblclick = () => {
    this.update()
  }

  onImageUrlChange(event) {
    this.flickr_link = null
    return this.setSelectedImage({src: $(event.currentTarget).val()})
  }

  onDecorativeChange() {
    if (this.$("[name='image[data-decorative]']").is(':checked')) {
      this.$("[name='image[alt]']").attr('disabled', true)
    } else {
      this.$("[name='image[alt]']").removeAttr('disabled')
    }
  }

  close() {
    super.close(...arguments)
    this.restoreCaret()
  }

  restoreCaret() {
    this.editor.selection.moveToBookmark(this.prevSelection)
    ReactDOM.unmountComponentAtNode(this.$el[0].querySelector('#tabUploaded'))
  }

  generateImageHtml() {
    let imgHtml = this.editor.dom.createHTML('img', this.getAttributes())
    if (this.flickr_link) {
      imgHtml = `<a href='${htmlEscape(this.flickr_link)}'>${imgHtml}</a>`
    }
    return imgHtml
  }

  update() {
    this.restoreCaret()
    if (this.$selectedNode.is('img')) {
      // Kill the alt/decorative props (but they get added back if needed)
      this.$selectedNode.removeAttr('alt')
      this.$selectedNode.removeAttr('data-decorative')
      this.$selectedNode.attr(this.getAttributes())
    } else {
      send(this.$editor, 'insert_code', this.generateImageHtml())
    }
    this.editor.focus()
    this.close()
  }
}

InsertUpdateImageView.prototype.template = template
InsertUpdateImageView.prototype.events = {
  'change [name="image[width]"]': 'constrainProportions',
  'change [name="image[height]"]': 'constrainProportions',
  'click .flickrImageResult, .treeFile': 'onFileLinkClick',
  'change [name="image[src]"]': 'onImageUrlChange',
  'tabsshow .imageSourceTabs': 'onTabsshow',
  'dblclick .flickrImageResult, .treeFile': 'onFileLinkDblclick',
  'change [name="image[data-decorative]"]': 'onDecorativeChange'
}
InsertUpdateImageView.prototype.dialogOptions = {
  id: 'rce__insert_edit_image',
  width: 625,
  title: I18n.t('titles.insert_edit_image', 'Insert / Edit Image'),
  destroy: true
}
