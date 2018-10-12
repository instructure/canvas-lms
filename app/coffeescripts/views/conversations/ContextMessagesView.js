#
# Copyright (C) 2013 - present Instructure, Inc.
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
  '../CollectionView'
  '../conversations/ContextMessageView'
], (CollectionView, ContextMessageView) ->

  class ContextMessagesView extends CollectionView
    itemView: ContextMessageView

    initialize: (options) ->
      super
      @collection.each (model) =>
        model.bind("removeView", @handleChildViewRemoval)

    handleChildViewRemoval: (e) ->
      el = e.view.$el
      index = el.index()
      hasSiblings = el.siblings().length > 0
      prev = el.prev().find('.delete-btn')
      next = el.next().find('.delete-btn')
      e.view.remove()

      if (index > 0)
        prev.focus()
      else
        if (hasSiblings)
          next.focus()
        else
          $('#add-message-attachment-button').focus()
