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

import CollectionView from '../CollectionView'
import ContextMessageView from './ContextMessageView'

export default class ContextMessagesView extends CollectionView {
  static initClass() {
    this.prototype.itemView = ContextMessageView
  }

  initialize(options) {
    super.initialize(...arguments)
    return this.collection.each(model => model.bind('removeView', this.handleChildViewRemoval))
  }

  handleChildViewRemoval(e) {
    const el = e.view.$el
    const index = el.index()
    const hasSiblings = el.siblings().length > 0
    const prev = el.prev().find('.delete-btn')
    const next = el.next().find('.delete-btn')
    e.view.remove()

    if (index > 0) {
      return prev.focus()
    } else if (hasSiblings) {
      return next.focus()
    } else {
      $('#add-message-attachment-button').focus()
    }
  }
}
ContextMessagesView.initClass()
