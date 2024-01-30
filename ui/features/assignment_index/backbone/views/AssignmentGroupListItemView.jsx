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

/* eslint-disable no-void */

import {extend} from '@canvas/backbone/utils'
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import * as MoveItem from '@canvas/move-item-tray'
import Cache from '../../cache'
import DraggableCollectionView from './DraggableCollectionView'
import AssignmentListItemView from './AssignmentListItemView'
import CreateAssignmentView from './CreateAssignmentView'
import CreateGroupView from './CreateGroupView'
import DeleteGroupView from './DeleteGroupView'
import preventDefault from '@canvas/util/preventDefault'
import template from '../../jst/AssignmentGroupListItem.handlebars'
import AssignmentKeyBindingsMixin from '../mixins/AssignmentKeyBindingsMixin'
import {shimGetterShorthand} from '@canvas/util/legacyCoffeesScriptHelpers'
import React from 'react'
import ReactDOM from 'react-dom'
import ContentTypeExternalToolTray from '@canvas/trays/react/ContentTypeExternalToolTray'
import {ltiState} from '@canvas/lti/jquery/messages'

const I18n = useI18nScope('AssignmentGroupListItemView')

extend(AssignmentGroupListItemView, DraggableCollectionView)

function AssignmentGroupListItemView() {
  this.setExternalToolTray = this.setExternalToolTray.bind(this)
  this.reloadPage = this.reloadPage.bind(this)
  this.openExternalTool = this.openExternalTool.bind(this)
  this.lastVisibleGroup = this.lastVisibleGroup.bind(this)
  this.focusOnFirstGroup = this.focusOnFirstGroup.bind(this)
  this.focusOnAssignment = this.focusOnAssignment.bind(this)
  this.focusOnGroup = this.focusOnGroup.bind(this)
  this.previousGroup = this.previousGroup.bind(this)
  this.nextGroup = this.nextGroup.bind(this)
  this.visibleGroupsInCollection = this.visibleGroupsInCollection.bind(this)
  this.lastAssignment = this.lastAssignment.bind(this)
  this.firstAssignment = this.firstAssignment.bind(this)
  this.hasVisibleAssignments = this.hasVisibleAssignments.bind(this)
  this.visibleAssignments = this.visibleAssignments.bind(this)
  this.deleteItem = this.deleteItem.bind(this)
  this.editItem = this.editItem.bind(this)
  this.addItem = this.addItem.bind(this)
  this.goToPrevItem = this.goToPrevItem.bind(this)
  this.goToNextItem = this.goToNextItem.bind(this)
  this.isVisible = this.isVisible.bind(this)
  this.onMoveContents = this.onMoveContents.bind(this)
  this.onMoveGroup = this.onMoveGroup.bind(this)
  this.toggleArrowWithKeyboard = this.toggleArrowWithKeyboard.bind(this)
  this.toggleArrow = this.toggleArrow.bind(this)
  this.collapse = this.collapse.bind(this)
  this.expand = this.expand.bind(this)
  this.endSort = this.endSort.bind(this)
  this.startSort = this.startSort.bind(this)
  this.createRulesToolTip = this.createRulesToolTip.bind(this)
  this.render = this.render.bind(this)
  return AssignmentGroupListItemView.__super__.constructor.apply(this, arguments)
}

AssignmentGroupListItemView.mixin(AssignmentKeyBindingsMixin)

AssignmentGroupListItemView.optionProperty('course')

AssignmentGroupListItemView.optionProperty('userIsAdmin')

AssignmentGroupListItemView.prototype.tagName = 'li'

AssignmentGroupListItemView.prototype.className = 'item-group-condensed'

AssignmentGroupListItemView.prototype.itemView = AssignmentListItemView

AssignmentGroupListItemView.prototype.template = template

AssignmentGroupListItemView.child('createAssignmentView', '[data-view=createAssignment]')

AssignmentGroupListItemView.child('editGroupView', '[data-view=editAssignmentGroup]')

AssignmentGroupListItemView.child('deleteGroupView', '[data-view=deleteAssignmentGroup]')

AssignmentGroupListItemView.prototype.els = {
  ...AssignmentGroupListItemView.prototype.els,
  '.add_assignment': '$addAssignmentButton',
  '.delete_group': '$deleteGroupButton',
  '.edit_group': '$editGroupButton',
  '.move_group': '$moveGroupButton',
}

AssignmentGroupListItemView.prototype.events = {
  'click .element_toggler': 'toggleArrow',
  'keyclick .element_toggler': 'toggleArrowWithKeyboard',
  'click .tooltip_link': preventDefault(function () {}),
  'keydown .assignment_group': 'handleKeys',
  'click .move_contents': 'onMoveContents',
  'click .move_group': 'onMoveGroup',
  'click .ag-header-controls .menu_tool_link': 'openExternalTool',
}

AssignmentGroupListItemView.prototype.messages = shimGetterShorthand(
  {},
  {
    toggleMessage() {
      return I18n.t('toggle_message', 'toggle assignment visibility')
    },
  }
)

// call remove on children so that they can clean up old dialogs.
// this should eventually happen at a higher level (eg for all views), but
// we need to make sure that all children view are also children dom
// elements first.
AssignmentGroupListItemView.prototype.render = function () {
  if (this.createAssignmentView) {
    this.createAssignmentView.remove()
  }
  if (this.editGroupView) {
    this.editGroupView.remove()
  }
  if (this.deleteGroupView) {
    this.deleteGroupView.remove()
  }
  $('.ig-details').addClass('rendered')
  AssignmentGroupListItemView.__super__.render.call(this, this.canManage())
  if (this.model) {
    return (this.model.view = this)
  }
}

AssignmentGroupListItemView.prototype.afterRender = function () {
  if (this.createAssignmentView) {
    this.createAssignmentView.hide()
    this.createAssignmentView.setTrigger(this.$addAssignmentButton)
  }
  if (this.editGroupView) {
    this.editGroupView.hide()
    this.editGroupView.setTrigger(this.$editGroupButton)
  }
  if (this.deleteGroupView) {
    this.deleteGroupView.hide()
    this.deleteGroupView.setTrigger(this.$deleteGroupButton)
  }
  if (this.model.hasRules()) {
    return this.createRulesToolTip()
  }
}

AssignmentGroupListItemView.prototype.createItemView = function (model) {
  const options = {
    userIsAdmin: this.userIsAdmin,
  }
  // eslint-disable-next-line new-cap
  return new this.itemView(
    $.extend(
      {},
      {
        model,
      },
      options
    )
  )
}

AssignmentGroupListItemView.prototype.createRulesToolTip = function () {
  const link = this.$el.find('.tooltip_link')
  return link.tooltip({
    position: {
      my: 'center top',
      at: 'center bottom+10',
      collision: 'fit fit',
    },
    tooltipClass: 'center top vertical',
    content() {
      return $(link.data('tooltipSelector')).html()
    },
  })
}

AssignmentGroupListItemView.prototype.initialize = function () {
  this.initializeCollection()
  AssignmentGroupListItemView.__super__.initialize.apply(this, arguments)
  this.assignment_group_menu_tools = ENV.assignment_group_menu_tools || []
  this.initializeChildViews()
  // we need the following line in order to access this view later
  this.model.groupView = this
  return this.initCache()
}

AssignmentGroupListItemView.prototype.initializeCollection = function () {
  this.model.get('assignments').each(function (assign) {
    if (assign.multipleDueDates()) {
      return assign.doNotParse()
    }
  })
  this.collection = this.model.get('assignments')
  return this.collection.on(
    'add',
    (function (_this) {
      return function () {
        return _this.expand(false)
      }
    })(this)
  )
}

AssignmentGroupListItemView.prototype.initializeChildViews = function () {
  this.editGroupView = false
  this.createAssignmentView = false
  this.deleteGroupView = false
  if (this.canAdd()) {
    this.editGroupView = new CreateGroupView({
      assignmentGroup: this.model,
      userIsAdmin: this.userIsAdmin,
    })
    this.createAssignmentView = new CreateAssignmentView({
      assignmentGroup: this.model,
    })
  }
  if (this.canDelete()) {
    return (this.deleteGroupView = new DeleteGroupView({
      model: this.model,
    }))
  }
}

AssignmentGroupListItemView.prototype.initCache = function () {
  $.extend(true, this, Cache)
  this.cache.use('localStorage')
  const key = this.cacheKey()
  if (this.cache.get(key) == null) {
    return this.cache.set(key, true)
  }
}

AssignmentGroupListItemView.prototype.initSort = function () {
  AssignmentGroupListItemView.__super__.initSort.call(this, {
    handle: '.draggable-handle',
  })
  return this.$list.on('sortactivate', this.startSort).on('sortdeactivate', this.endSort)
}

AssignmentGroupListItemView.prototype.startSort = function (e, ui) {
  // When there is 1 assignment in this group and you drag an assignment
  // from another group, don't insert the noItemView
  if (this.collection.length === 1 && $(ui.placeholder).data('group') === this.model.id) {
    return this.insertNoItemView()
  }
}

AssignmentGroupListItemView.prototype.endSort = function (_e, _ui) {
  if (this.collection.length === 0 && this.$list.children().length < 1) {
    return this.insertNoItemView()
  } else if (this.$list.children().length > 1) {
    return this.removeNoItemView()
  }
}

AssignmentGroupListItemView.prototype.toJSON = function () {
  const data = this.model.toJSON()
  let ref
  const showWeight =
    ((ref = this.course) != null ? ref.get('apply_assignment_group_weights') : void 0) &&
    data.group_weight != null
  const canMove = this.model.collection.length > 1
  return Object.assign(data, {
    course_home: ENV.COURSE_HOME,
    canMove,
    canDelete: this.canDelete(),
    showRules: this.model.hasRules(),
    rulesText: I18n.t('rules_text', 'Rule', {
      count: this.model.countRules(),
    }),
    displayableRules: this.displayableRules(),
    showWeight,
    groupWeight: data.group_weight,
    toggleMessage: this.messages.toggleMessage,
    hasFrozenAssignments:
      this.model.hasFrozenAssignments != null && this.model.hasFrozenAssignments(),
    hasIntegrationData: this.model.hasIntegrationData != null && this.model.hasIntegrationData(),
    postToSISName: ENV.SIS_NAME,
    assignmentGroupMenuPlacements: this.assignment_group_menu_tools,
    ENV,
  })
}

AssignmentGroupListItemView.prototype.displayableRules = function () {
  const rules = this.model.rules() || {}
  const results = []
  if (rules.drop_lowest != null && rules.drop_lowest > 0) {
    results.push(
      I18n.t(
        'drop_lowest_rule',
        {
          one: 'Drop the lowest score',
          other: 'Drop the lowest %{count} scores',
        },
        {
          count: rules.drop_lowest,
        }
      )
    )
  }
  if (rules.drop_highest != null && rules.drop_highest > 0) {
    results.push(
      I18n.t(
        'drop_highest_rule',
        {
          one: 'Drop the highest score',
          other: 'Drop the highest %{count} scores',
        },
        {
          count: rules.drop_highest,
        }
      )
    )
  }
  if (rules.never_drop != null && rules.never_drop.length > 0) {
    rules.never_drop.forEach(
      (function (_this) {
        return function (never_drop_assignment_id) {
          let name
          const assign = _this.model.get('assignments').findWhere({
            id: never_drop_assignment_id,
          })
          // TODO: students won't see never drop rules for unpublished
          // assignments because we don't know if the assignment is missing
          // because it is unpublished or because it has been moved or deleted.
          // Once those cases are handled better, we can add a default here.
          if ((name = assign != null ? assign.get('name') : void 0)) {
            return results.push(
              I18n.t('never_drop_rule', 'Never drop %{assignment_name}', {
                assignment_name: name,
              })
            )
          }
        }
      })(this)
    )
  }
  return results
}

AssignmentGroupListItemView.prototype.search = function (regex, gradingPeriod) {
  this.resetBorders()
  const assignmentCount = this.collection.reduce(
    (function (_this) {
      return function (count, as) {
        if (as.search(regex, gradingPeriod)) {
          count++
        }
        return count
      }
    })(this),
    0
  )
  const atleastone = assignmentCount > 0
  if (atleastone) {
    this.show()
    this.expand(false)
    this.borderFix()
  } else {
    this.hide()
  }
  return assignmentCount
}

AssignmentGroupListItemView.prototype.endSearch = function () {
  this.resetBorders()
  this.show()
  this.collapseIfNeeded()
  this.resetNoToggleCache()
  return this.collection.each(
    (function (_this) {
      return function (as) {
        return as.endSearch()
      }
    })(this)
  )
}

AssignmentGroupListItemView.prototype.resetBorders = function () {
  this.$('.first_visible').removeClass('first_visible')
  return this.$('.last_visible').removeClass('last_visible')
}

AssignmentGroupListItemView.prototype.borderFix = function () {
  this.$('.search_show').first().addClass('first_visible')
  return this.$('.search_show').last().addClass('last_visible')
}

AssignmentGroupListItemView.prototype.shouldBeExpanded = function () {
  return this.cache.get(this.cacheKey())
}

AssignmentGroupListItemView.prototype.collapseIfNeeded = function () {
  if (!this.shouldBeExpanded()) {
    return this.collapse(false)
  }
}

AssignmentGroupListItemView.prototype.expand = function (toggleCache) {
  if (toggleCache == null) {
    toggleCache = true
  }
  if (!toggleCache) {
    this._setNoToggleCache()
  }
  if (!this.currentlyExpanded()) {
    return this.toggleCollapse()
  }
}

AssignmentGroupListItemView.prototype.collapse = function (toggleCache) {
  if (toggleCache == null) {
    toggleCache = true
  }
  if (!toggleCache) {
    this._setNoToggleCache()
  }
  if (this.currentlyExpanded()) {
    return this.toggleCollapse()
  }
}

AssignmentGroupListItemView.prototype.toggleCollapse = function (toggleCache) {
  if (toggleCache == null) {
    toggleCache = true
  }
  if (!toggleCache) {
    this._setNoToggleCache()
  }
  return this.$el.find('.element_toggler').click()
}

AssignmentGroupListItemView.prototype._setNoToggleCache = function () {
  return this.$el.find('.element_toggler').data('noToggleCache', true)
}

AssignmentGroupListItemView.prototype.currentlyExpanded = function () {
  if (this.$el.find('.element_toggler').attr('aria-expanded') === 'false') {
    return false
  } else {
    return true
  }
}

AssignmentGroupListItemView.prototype.cacheKey = function () {
  return [
    'course',
    this.course.get('id'),
    'user',
    this.currentUserId(),
    'ag',
    this.model.get('id'),
    'expanded',
  ]
}

AssignmentGroupListItemView.prototype.toggleArrow = function (ev) {
  const arrow = $(ev.currentTarget).children('i')
  arrow.toggleClass('icon-mini-arrow-down').toggleClass('icon-mini-arrow-right')
  if (!$(ev.currentTarget).data('noToggleCache')) {
    this.toggleCache()
  }
  return this.resetNoToggleCache(ev.currentTarget)
}

AssignmentGroupListItemView.prototype.toggleArrowWithKeyboard = function (ev) {
  $(ev.target).click()
  return false
}

AssignmentGroupListItemView.prototype.resetNoToggleCache = function (selector) {
  let obj
  if (selector == null) {
    selector = null
  }
  if (selector != null) {
    obj = $(selector)
  } else {
    obj = this.$el.find('.element_toggler')
  }
  return obj.data('noToggleCache', false)
}

AssignmentGroupListItemView.prototype.toggleCache = function () {
  const key = this.cacheKey()
  const expanded = !this.cache.get(key)
  return this.cache.set(key, expanded)
}

AssignmentGroupListItemView.prototype.onMoveGroup = function () {
  this.moveTrayProps = {
    title: I18n.t('Move Group'),
    items: [
      {
        id: this.model.get('id'),
        title: this.model.get('name'),
      },
    ],
    moveOptions: {
      siblings: MoveItem.backbone.collectionToItems(this.model.collection),
    },
    onMoveSuccess: (function (_this) {
      return function (res) {
        return MoveItem.backbone.reorderInCollection(res.data.order, _this.model)
      }
    })(this),
    focusOnExit: (function (_this) {
      return function () {
        return document.querySelector('#assignment_group_' + _this.model.id + ' a[id*=manage_link]')
      }
    })(this),
    formatSaveUrl: (function (_this) {
      return function () {
        return ENV.URLS.sort_url
      }
    })(this),
  }
  return MoveItem.renderTray(this.moveTrayProps, document.getElementById('not_right_side'))
}

AssignmentGroupListItemView.prototype.onMoveContents = function () {
  const groupItems = MoveItem.backbone.collectionToItems(
    this.model,
    (function (_this) {
      return function (col) {
        return col.get('assignments')
      }
    })(this)
  )
  groupItems[0].groupId = this.model.get('id')
  this.moveTrayProps = {
    title: I18n.t('Move Contents Into'),
    items: groupItems,
    moveOptions: {
      groupsLabel: I18n.t('Assignment Group'),
      groups: MoveItem.backbone.collectionToGroups(
        this.model.collection,
        (function (_this) {
          return function (col) {
            return col.get('assignments')
          }
        })(this)
      ),
      excludeCurrent: true,
    },
    onMoveSuccess: (function (_this) {
      return function (res) {
        const keys = {
          model: 'assignments',
          parent: 'assignment_group_id',
        }
        return MoveItem.backbone.reorderAllItemsIntoNewCollection(
          res.data.order,
          res.groupId,
          _this.model,
          keys
        )
      }
    })(this),
    focusOnExit: (function (_this) {
      return function () {
        return document.querySelector('#assignment_group_' + _this.model.id + ' a[id*=manage_link]')
      }
    })(this),
    formatSaveUrl(arg) {
      const groupId = arg.groupId
      return ENV.URLS.assignment_sort_base_url + '/' + groupId + '/reorder'
    },
  }
  return MoveItem.renderTray(this.moveTrayProps, document.getElementById('not_right_side'))
}

AssignmentGroupListItemView.prototype.hasMasterCourseRestrictedAssignments = function () {
  return this.model.get('assignments').any(function (m) {
    return m.isRestrictedByMasterCourse()
  })
}

AssignmentGroupListItemView.prototype.canDelete = function () {
  return (
    ENV.PERMISSIONS.manage_assignments_delete &&
    (this.userIsAdmin || this.model.canDelete()) &&
    !this.hasMasterCourseRestrictedAssignments()
  )
}

AssignmentGroupListItemView.prototype.canAdd = function () {
  return ENV.PERMISSIONS.manage_assignments_add
}

AssignmentGroupListItemView.prototype.canManage = function () {
  return ENV.PERMISSIONS.manage
}

AssignmentGroupListItemView.prototype.currentUserId = function () {
  return ENV.current_user_id
}

AssignmentGroupListItemView.prototype.isVisible = function () {
  return $('#assignment_group_' + this.model.id).is(':visible')
}

AssignmentGroupListItemView.prototype.goToNextItem = function () {
  if (this.hasVisibleAssignments()) {
    return this.focusOnAssignment(this.firstAssignment())
  } else if (this.nextGroup() != null) {
    return this.focusOnGroup(this.nextGroup())
  } else {
    return this.focusOnFirstGroup()
  }
}

AssignmentGroupListItemView.prototype.goToPrevItem = function () {
  if (this.previousGroup() != null) {
    if (this.previousGroup().view.hasVisibleAssignments()) {
      return this.focusOnAssignment(this.previousGroup().view.lastAssignment())
    } else {
      return this.focusOnGroup(this.previousGroup())
    }
  } else if (this.lastVisibleGroup().view.hasVisibleAssignments()) {
    return this.focusOnAssignment(this.lastVisibleGroup().view.lastAssignment())
  } else {
    return this.focusOnGroup(this.lastVisibleGroup())
  }
}

AssignmentGroupListItemView.prototype.addItem = function () {
  return $('.add_assignment', '#assignment_group_' + this.model.id).click()
}

AssignmentGroupListItemView.prototype.editItem = function () {
  return $(".edit_group[data-focus-returns-to='ag_" + this.model.id + "_manage_link']").click()
}

AssignmentGroupListItemView.prototype.deleteItem = function () {
  return $(".delete_group[data-focus-returns-to='ag_" + this.model.id + "_manage_link']").click()
}

AssignmentGroupListItemView.prototype.visibleAssignments = function () {
  return this.collection.filter(function (assign) {
    return assign.attributes.hidden !== true
  })
}

AssignmentGroupListItemView.prototype.hasVisibleAssignments = function () {
  return this.currentlyExpanded() && this.visibleAssignments().length
}

AssignmentGroupListItemView.prototype.firstAssignment = function () {
  return this.visibleAssignments()[0]
}

AssignmentGroupListItemView.prototype.lastAssignment = function () {
  return this.visibleAssignments()[this.visibleAssignments().length - 1]
}

AssignmentGroupListItemView.prototype.visibleGroupsInCollection = function () {
  return this.model.collection.filter(function (group) {
    return group.view.isVisible()
  })
}

AssignmentGroupListItemView.prototype.nextGroup = function () {
  const place_in_groups_collection = this.visibleGroupsInCollection().indexOf(this.model)
  return this.visibleGroupsInCollection()[place_in_groups_collection + 1]
}

AssignmentGroupListItemView.prototype.previousGroup = function () {
  const place_in_groups_collection = this.visibleGroupsInCollection().indexOf(this.model)
  return this.visibleGroupsInCollection()[place_in_groups_collection - 1]
}

AssignmentGroupListItemView.prototype.focusOnGroup = function (group) {
  return $('#assignment_group_' + group.attributes.id)
    .attr('tabindex', -1)
    .focus()
}

AssignmentGroupListItemView.prototype.focusOnAssignment = function (assignment) {
  return $('#assignment_' + assignment.id)
    .attr('tabindex', -1)
    .focus()
}

AssignmentGroupListItemView.prototype.focusOnFirstGroup = function () {
  return $('.assignment_group').filter(':visible').first().attr('tabindex', -1).focus()
}

AssignmentGroupListItemView.prototype.lastVisibleGroup = function () {
  const last_group_index = this.visibleGroupsInCollection().length - 1
  return this.visibleGroupsInCollection()[last_group_index]
}

AssignmentGroupListItemView.prototype.openExternalTool = function (ev) {
  if (ev !== null) {
    ev.preventDefault()
  }
  const tool = this.assignment_group_menu_tools.find(
    (function (_this) {
      return function (t) {
        return t.id === ev.target.dataset.toolId
      }
    })(this)
  )
  return this.setExternalToolTray(tool, this.$el.find('.al-trigger')[0])
}

AssignmentGroupListItemView.prototype.reloadPage = function () {
  return window.location.reload()
}

AssignmentGroupListItemView.prototype.setExternalToolTray = function (tool, returnFocusTo) {
  const handleDismiss = (function (_this) {
    return function () {
      let ref
      _this.setExternalToolTray(null)
      returnFocusTo.focus()
      if (
        ltiState != null ? ((ref = ltiState.tray) != null ? ref.refreshOnClose : void 0) : void 0
      ) {
        return _this.reloadPage()
      }
    }
  })(this)
  const groupData = {
    id: this.model.get('id'),
    name: this.model.get('name'),
  }
  const props = {
    tool,
    placement: 'assignment_group_menu',
    acceptedResourceTypes: ['assignment'],
    targetResourceType: 'assignment',
    allowItemSelection: false,
    selectableItems: [groupData],
    onDismiss: handleDismiss,
    open: tool !== null,
  }
  const component = React.createElement(ContentTypeExternalToolTray, props)
  // eslint-disable-next-line react/no-render-return-value
  return ReactDOM.render(component, $('#external-tool-mount-point')[0])
}

export default AssignmentGroupListItemView
