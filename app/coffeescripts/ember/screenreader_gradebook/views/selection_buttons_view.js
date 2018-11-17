//
// Copyright (C) 2014 - present Instructure, Inc.
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

import Ember from 'ember'
import I18n from 'i18n!sr_gradebook'

const SelectionButtonsView = Ember.View.extend({
  templateName: 'content_selection/selection_buttons',

  list: null,
  type: null,
  selected: null,

  classPath: function() {
    return `${this.get('type')}_navigation`
  }.property('type'),

  previousLabel: function() {
    const type = this.get('type').capitalize()
    return I18n.t('previous_object', 'Previous %{type}', {type})
  }.property('type'),

  nextLabel: function() {
    const type = this.get('type').capitalize()
    return I18n.t('next_object', 'Next %{type}', {type})
  }.property('type'),

  disablePreviousButton: Ember.computed.lte('currentIndex', 0),

  disableNextButton: function() {
    const next = this.get('list').objectAt(this.get('currentIndex') + 1)
    return !(this.get('list.length') && next)
  }.property('currentIndex', 'list.@each'),

  currentIndex: function() {
    return this.get('list').indexOf(this.get('selected'))
  }.property('selected', 'list.@each'),

  actions: {
    selectItem(goTo) {
      const index = this.get('currentIndex')
      const list = this.get('list')
      let item = null

      if (goTo === 'previous') {
        item = list.objectAt(index - 1)
        if (!list.objectAt(index - 2)) {
          this.$('.next_object').focus()
        }
      }
      if (goTo === 'next') {
        item = list.objectAt(index + 1)
        if (!list.objectAt(index + 2)) {
          this.$('.previous_object').focus()
        }
      }

      if (item) {
        this.set('selected', item)
        return this.get('controller').send('selectItem', this.get('type'), item)
      }
    }
  }
})

export default SelectionButtonsView
