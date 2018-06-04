//
// Copyright (C) 2013 - present Instructure, Inc.
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

import I18n from 'i18n!conversations'
import {View} from 'Backbone'
import _ from 'underscore'
import template from 'jst/conversations/message'
import React from 'react'
import ReactDOM from 'react-dom'
import Checkbox from '@instructure/ui-forms/lib/components/Checkbox'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'

export default class MessageView extends View {
  initialize(...args) {
    super.initialize(...args)
    return this.attachModel()
  }

  attachModel() {
    this.model.on('change:starred', this.setStarBtnChecked.bind(this))
    this.model.on('change:workflow_state', () =>
      this.$readBtn.toggleClass('read', this.model.get('workflow_state') !== 'unread')
    )
    this.model.on('change:selected', this.setSelected.bind(this))
  }

  renderSelectCheckbox() {
    const subject = this.model.get('subject') || I18n.t('No Subject')
    ReactDOM.render(
      <Checkbox
        label={
          <ScreenReaderContent>
            {I18n.t('Select Conversation %{subject}', {subject})}
          </ScreenReaderContent>
        }
        checked={!!this.model.get('selected')}
        onChange={() => this.model.set('selected', !this.model.get('selected'))}
      />,
      this.$selectCheckbox[0]
    )
  }

  setSelected(m) {
    const selected = m.get('selected')
    this.$el.toggleClass('active', selected)
    this.renderSelectCheckbox()
  }

  onSelect(e) {
    if (
      (e && e.target.className.match(/star|read-state/)) ||
      this.$selectCheckbox[0].contains(e.target)
    ) return

    if (e.shiftKey) return this.model.collection.selectRange(this.model)

    const modifier = e.metaKey || e.ctrlKey
    if (this.model.get('selected') && modifier) return this.deselect(modifier)
    return this.select(modifier)
  }

  select(modifier) {
    if (!modifier) {
      _.each(this.model.collection.without(this.model), m => m.set('selected', false))
    }
    this.model.set('selected', true)
    if (this.model.unread()) {
      this.model.set('workflow_state', 'read')
      if (this.model.get('for_submission')) {
        return this.model.save()
      }
    }
  }

  deselect(modifier) {
    if (modifier) this.model.set('selected', false)
  }

  setStarBtnCheckedScreenReaderMessage() {
    const subject = this.model.get('subject')
    const text = this.model.starred()
      ? subject
        ? I18n.t('Starred "%{subject}", Click to unstar.', {subject})
        : I18n.t('Starred "(No Subject)", Click to unstar.')
      : subject
        ? I18n.t('Not starred "%{subject}", Click to star.', {subject})
        : I18n.t('Not starred "(No Subject)", Click to star.')
    this.$starBtnScreenReaderMessage.text(text)
  }

  setStarBtnChecked() {
    this.$starBtn.attr({
      'aria-checked': this.model.starred(),
      title: this.model.starred() ? this.messages.unstar : this.messages.star
    })
    this.$starBtn.toggleClass('active', this.model.starred())
    this.setStarBtnCheckedScreenReaderMessage()
  }

  toggleStar(e) {
    e.preventDefault()
    this.model.toggleStarred()
    this.model.save()
    this.setStarBtnChecked()
  }

  toggleRead(e) {
    e.preventDefault()
    this.model.toggleReadState()
    this.model.save()
    this.$readBtn.attr({
      'aria-checked': this.model.unread(),
      title: this.model.unread() ? this.messages.read : this.messages.unread
    })
  }

  onMouseDown(e) {
    if (e.shiftKey) {
      e.preventDefault()
      setTimeout(() => window.getSelection().removeAllRanges(), 0) // IE
    }
  }

  afterRender() {
    this.renderSelectCheckbox()
  }

  remove() {
    ReactDOM.unmountComponentAtNode(this.$selectCheckbox[0])
    super.remove(...arguments)
  }

  toJSON() {
    return this.model.toJSON().conversation
  }
}

Object.assign(MessageView.prototype, {
  tagName: 'li',
  template,
  els: {
    '.star-btn': '$starBtn',
    '.StarButton-LabelContainer': '$starBtnScreenReaderMessage',
    '.read-state': '$readBtn',
    '.select-checkbox': '$selectCheckbox'
  },
  events: {
    'click': 'onSelect',
    'click .open-message': 'onSelect',
    'click .star-btn': 'toggleStar',
    'click .read-state': 'toggleRead',
    'mousedown': 'onMouseDown'
  },
  messages: {
    read: I18n.t('Mark as read'),
    unread: I18n.t('Mark as unread'),
    star: I18n.t('Star conversation'),
    unstar: I18n.t('Unstar conversation')
  }
})
