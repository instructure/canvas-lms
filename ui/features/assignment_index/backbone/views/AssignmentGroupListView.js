/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {extend} from '@canvas/backbone/utils'
import {extend as lodashExtend} from 'lodash'
import $ from 'jquery'
import SortableCollectionView from './SortableCollectionView'
import AssignmentGroupListItemView from './AssignmentGroupListItemView'
import template from '../../jst/AssignmentGroupList.handlebars'
import NoAssignmentsListItem from '../../jst/NoAssignmentsListItem.handlebars'

extend(AssignmentGroupListView, SortableCollectionView)

function AssignmentGroupListView() {
  this.expand = this.expand.bind(this)
  this.collapse = this.collapse.bind(this)
  this.handleExtraClick = this.handleExtraClick.bind(this)
  this.renderOnReset = this.renderOnReset.bind(this)
  this.renderIfLoaded = this.renderIfLoaded.bind(this)
  this.renderItem = this.renderItem.bind(this)
  this.render = this.render.bind(this)
  return AssignmentGroupListView.__super__.constructor.apply(this, arguments)
}

AssignmentGroupListView.optionProperty('course')

AssignmentGroupListView.optionProperty('userIsAdmin')

AssignmentGroupListView.prototype.template = template

AssignmentGroupListView.prototype.itemView = AssignmentGroupListItemView

AssignmentGroupListView.optionProperty('assignment_sort_base_url')

AssignmentGroupListView.prototype.render = function () {
  return AssignmentGroupListView.__super__.render.call(this, ENV.PERMISSIONS.manage)
}

AssignmentGroupListView.prototype.renderItem = function (model) {
  const view = AssignmentGroupListView.__super__.renderItem.apply(this, arguments)
  model.groupView.collapseIfNeeded()
  return view
}

AssignmentGroupListView.prototype.createItemView = function (model) {
  const options = {
    parentCollection: this.collection,
    childKey: 'assignments',
    groupKey: 'assignment_group_id',
    groupId: model.id,
    reorderURL: this.createReorderURL(model.id),
    noItemTemplate: NoAssignmentsListItem,
    userIsAdmin: this.userIsAdmin,
  }
  // eslint-disable-next-line new-cap
  return new this.itemView(
    $.extend(
      {},
      this.itemViewOptions || {},
      {
        model,
      },
      options
    )
  )
}

AssignmentGroupListView.prototype.createReorderURL = function (id) {
  return this.assignment_sort_base_url + '/' + id + '/reorder'
}

// TODO: make menu a child view of listitem so that it can be rendered
// by itself, and so it can manage all of the dialog stuff,
AssignmentGroupListView.prototype.attachCollection = function () {
  AssignmentGroupListView.__super__.attachCollection.apply(this, arguments)
  this.itemViewOptions = {
    course: this.course,
  }
  this.collection.on('render', this.render)
  this.collection.on('add', this.renderIfLoaded)
  this.collection.on('remove', this.render)
  return this.collection.on('change:groupWeights', this.render)
}

AssignmentGroupListView.prototype.renderIfLoaded = function () {
  if (this.collection.loadedAll) {
    return this.render()
  }
}

AssignmentGroupListView.prototype.renderOnReset = function () {
  this.firstResetLanded = true
  return AssignmentGroupListView.__super__.renderOnReset.apply(this, arguments)
}

AssignmentGroupListView.prototype.toJSON = function () {
  const data = AssignmentGroupListView.__super__.toJSON.apply(this, arguments)
  return lodashExtend({}, data, {
    firstResetLanded: this.firstResetLanded,
  })
}

AssignmentGroupListView.prototype._initSort = function () {
  AssignmentGroupListView.__super__._initSort.call(this, {
    handle: '.sortable-handle',
  })
  this.$list.on('sortstart', this.collapse)
  return this.$list.on('sortstop', this.expand)
}

AssignmentGroupListView.prototype.handleExtraClick = function (e) {
  e.stopImmediatePropagation()
  // FF triggers an extra click when you drop the item, so we want to handle it here
  return $(e.target).off('click', this.handleExtraClick)
}

AssignmentGroupListView.prototype.collapse = function (e, ui) {
  const item = ui.item
  const id = item.children(':first').attr('data-id')
  item.find('#assignment_group_' + id + '_assignments').slideUp(100)
  ui.item.css('height', 'auto')
  const $toggler = item.find('.element_toggler').first()
  const arrow = $toggler.find('i').first()
  return arrow.removeClass('icon-mini-arrow-down').addClass('icon-mini-arrow-right')
}

AssignmentGroupListView.prototype.expand = function (e, ui) {
  const item = ui.item
  const $toggler = item.find('.element_toggler').first()
  $toggler.on('click', this.handleExtraClick)
  // remove the extra click handler for browsers that don't trigger the extra click
  setTimeout(
    (function (_this) {
      return function () {
        return $toggler.off('click', _this.handleExtraClick)
      }
    })(this),
    50
  )
  const id = item.children(':first').attr('data-id')
  const ag = this.collection.findWhere({
    id,
  })
  if (ag && ag.groupView.shouldBeExpanded()) {
    item.find('#assignment_group_' + id + '_assignments').slideDown(100)
    const arrow = $toggler.find('i').first()
    return arrow.addClass('icon-mini-arrow-down').removeClass('icon-mini-arrow-right')
  }
}

export default AssignmentGroupListView
