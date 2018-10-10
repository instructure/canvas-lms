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

import $ from 'jquery'
import GroupUsersView from './GroupUsersView'
import AssignToGroupMenu from './AssignToGroupMenu'
import Scrollable from './Scrollable'
import GroupCategoryCloneView from './GroupCategoryCloneView'
import groupHasSubmissions from '../../../util/groupHasSubmissions'

export default class UnassignedUsersView extends GroupUsersView {
  static initClass() {
    this.optionProperty('groupsCollection')
    this.optionProperty('category')

    this.prototype.defaults = {
      ...GroupUsersView.prototype.defaults,
      autoFetch: true, // load until below the viewport, don't wait for the user to scroll
      itemViewOptions: {
        canAssignToGroup: true,
        canEditGroupAssignment: false
      }
    }

    this.prototype.els = {
      ...GroupUsersView.prototype.els,
      '.no-results-wrapper': '$noResultsWrapper',
      '.no-results': '$noResults',
      '.invalid-filter': '$invalidFilter'
    }

    this.mixin(Scrollable)

    this.prototype.elementIndex = -1
    this.prototype.fromAddButton = false

    this.prototype.dropOptions = {
      accept: '.group-user',
      activeClass: 'droppable',
      hoverClass: 'droppable-hover',
      tolerance: 'pointer'
    }

    this.prototype.events = {
      'click .assign-to-group': 'focusAssignToGroup',
      'focus .assign-to-group': 'showAssignToGroup',
      'blur .assign-to-group': 'hideAssignToGroup',
      scroll: 'hideAssignToGroup'
    }
  }

  attach() {
    this.collection.on('reset', this.render)
    this.collection.on('remove', this.render)
    this.collection.on('moved', this.highlightUser)
    this.on('renderedItems', this.realAfterRender, this)

    this.collection.once('fetch', () => this.$noResultsWrapper.hide())
    return this.collection.on('fetched:last', () => this.$noResultsWrapper.show())
  }

  afterRender() {
    super.afterRender(...arguments)
    this.collection.load('first')
    this.$el
      .parent()
      .droppable(Object.assign({}, this.dropOptions))
      .unbind('drop')
      .on('drop', this._onDrop.bind(this))
    this.scrollContainer = this.heightContainer = this.$el
    return (this.$scrollableElement = this.$el.find('ul'))
  }

  realAfterRender() {
    const listElements = $('ul.collectionViewItems li.group-user', this.$el)
    if (this.elementIndex > -1 && listElements.length > 0) {
      const focusElement = $(
        listElements[this.elementIndex] || listElements[listElements.length - 1]
      )
      return focusElement.find('a.assign-to-group').focus()
    }
  }

  toJSON() {
    return {
      loading: !this.collection.loadedAll,
      count: this.collection.length,
      ENV
    }
  }

  remove() {
    if (this.assignToGroupMenu != null) {
      this.assignToGroupMenu.remove()
    }
    return super.remove(...arguments)
  }

  focusAssignToGroup(e) {
    e.preventDefault()
    e.stopPropagation()
    const $target = $(e.currentTarget)
    this.fromAddButton = true
    const assignToGroupMenu = this._getAssignToGroup()
    assignToGroupMenu.model = this.collection.getUser($target.data('user-id'))
    return assignToGroupMenu.showBy($target, true)
  }

  showAssignToGroup(e) {
    if (this.elementIndex === -1) {
      e.preventDefault()
      e.stopPropagation()
    }
    const $target = $(e.currentTarget)

    const assignToGroupMenu = this._getAssignToGroup()
    assignToGroupMenu.model = this.collection.getUser($target.data('user-id'))
    return assignToGroupMenu.showBy($target)
  }

  _getAssignToGroup() {
    if (!this.assignToGroupMenu) {
      this.assignToGroupMenu = new AssignToGroupMenu({collection: this.groupsCollection})
      this.assignToGroupMenu.on(
        'open',
        options =>
          (this.elementIndex = Array.prototype.indexOf.apply(
            $('ul.collectionViewItems li.group-user', this.$el),
            $(options.target).parent('li')
          ))
      )
      this.assignToGroupMenu.on('close', options => {
        const studentElements = $('li.group-user a.assign-to-group', this.$el)
        if (this.elementIndex !== -1) {
          if (studentElements.length === 0) {
            $('.filterable-unassigned-users').focus()
          } else if (options.escapePressed) {
            $(
              studentElements[this.elementIndex] || studentElements[studentElements.length - 1]
            ).focus()
          } else if (options.userMoved) {
            if (this.elementIndex === 0) {
              $('.filterable-unassigned-users').focus()
            } else {
              $(
                studentElements[this.elementIndex - 1] ||
                  studentElements[studentElements.length - 1]
              ).focus()
            }
          }
          return (this.elementIndex = -1)
        }
      })
    }
    return this.assignToGroupMenu
  }

  hideAssignToGroup(e) {
    if (!this.fromAddButton) {
      if (this.assignToGroupMenu != null) {
        this.assignToGroupMenu.hide()
      }
      setTimeout(() => {
        // Element with next focus will not get focus until _after_ 'focusout' and 'blur' have been called.
        if (!this.$el.find('a.assign-to-group').is(':focus')) return (this.elementIndex = -1)
      }, 100)
    }
    return (this.fromAddButton = false)
  }

  setFilter(search_term, options) {
    const searchDefer = this.collection.search(search_term, options)
    if (searchDefer) {
      return searchDefer.always(() => {
        if (search_term.length < 3) {
          const shouldShow = search_term.length > 0
          this.$invalidFilter.toggleClass('hidden', !shouldShow)
          return this.$noResultsWrapper.toggle(shouldShow)
        }
      })
    }
  }

  canAssignToGroup() {
    return this.options.canAssignToGroup && this.groupsCollection.length
  }

  // #
  // handle drop events on '.unassigned-students'
  // ui.draggable: the user being dragged
  _onDrop(e, ui) {
    const user = ui.draggable.data('model')

    if (user.has('group') && groupHasSubmissions(user.get('group'))) {
      this.cloneCategoryView = new GroupCategoryCloneView({
        model: this.collection.category,
        openedFromCaution: true
      })
      this.cloneCategoryView.open()
      return this.cloneCategoryView.on('close', () => {
        if (this.cloneCategoryView.cloneSuccess) {
          return window.location.reload()
        } else if (this.cloneCategoryView.changeGroups) {
          return this.moveUser(user)
        }
      })
    } else {
      return this.moveUser(user)
    }
  }

  moveUser(user) {
    return setTimeout(() => this.category.reassignUser(user, null))
  }

  _initDrag(view) {
    super._initDrag(...arguments)
    return view.$el.on('dragstart', (event, ui) => (this.elementIndex = -1))
  }
}
UnassignedUsersView.initClass()
