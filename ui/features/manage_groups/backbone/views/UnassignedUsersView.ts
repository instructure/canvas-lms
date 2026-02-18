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
import groupHasSubmissions from '../../groupHasSubmissions'

export default class UnassignedUsersView extends GroupUsersView {
  static initClass() {
    // @ts-expect-error - Backbone View property
    this.optionProperty('groupsCollection')
    // @ts-expect-error - Backbone View property
    this.optionProperty('category')

    this.prototype.defaults = {
      ...GroupUsersView.prototype.defaults,
      // @ts-expect-error - Legacy Backbone typing
      autoFetch: true, // load until below the viewport, don't wait for the user to scroll
      itemViewOptions: {
        canAssignToGroup: true,
        canEditGroupAssignment: false,
      },
    }

    this.prototype.els = {
      ...GroupUsersView.prototype.els,
      '.no-results-wrapper': '$noResultsWrapper',
      '.no-results': '$noResults',
      '.invalid-filter': '$invalidFilter',
    }

    // @ts-expect-error - Backbone View property
    this.mixin(Scrollable)

    // @ts-expect-error - Backbone View property
    this.prototype.elementIndex = -1
    // @ts-expect-error - Backbone View property
    this.prototype.fromAddButton = false

    // @ts-expect-error - Backbone View property
    this.prototype.dropOptions = {
      accept: '.group-user',
      activeClass: 'droppable',
      hoverClass: 'droppable-hover',
      tolerance: 'pointer',
    }

    // @ts-expect-error - Backbone View property
    this.prototype.events = {
      'click .assign-to-group': 'focusAssignToGroup',
      'blur .assign-to-group': 'hideAssignToGroup',
      scroll: 'hideAssignToGroup',
    }
  }

  attach() {
    // @ts-expect-error - Backbone View property
    this.collection.on('reset', this.render, this)
    // @ts-expect-error - Backbone View property
    this.collection.on('remove', this.render, this)
    // @ts-expect-error - Backbone View property
    this.collection.on('moved', this.highlightUser, this)
    // @ts-expect-error - Backbone View property
    this.on('renderedItems', this.realAfterRender, this)

    // @ts-expect-error - Backbone View property
    this.collection.once('fetch', () => this.$noResultsWrapper.hide())
    // @ts-expect-error - Backbone View property
    return this.collection.on('fetched:last', () => this.$noResultsWrapper.show())
  }

  afterRender() {
    super.afterRender(...arguments)
    // @ts-expect-error - Backbone View property
    this.collection.load('first')
    // @ts-expect-error - Backbone View property
    this.$el
      .parent()
      // @ts-expect-error - Backbone View property
      .droppable({...this.dropOptions})
      .unbind('drop')
      .on('drop', this._onDrop.bind(this))
    // @ts-expect-error - Backbone View property
    this.scrollContainer = this.heightContainer = this.$el
    // @ts-expect-error - Backbone View property
    return (this.$scrollableElement = this.$el.find('ul'))
  }

  realAfterRender() {
    // @ts-expect-error - Backbone View property
    const listElements = $('ul.collectionViewItems li.group-user', this.$el)
    // @ts-expect-error - Backbone View property
    if (this.elementIndex > -1 && listElements.length > 0) {
      const focusElement = $(
        // @ts-expect-error - Backbone View property
        listElements[this.elementIndex] || listElements[listElements.length - 1],
      )
      return focusElement.find('a.assign-to-group').focus()
    }
  }

  // @ts-expect-error - Legacy Backbone typing
  toJSON() {
    return {
      // @ts-expect-error - Backbone View property
      loading: !this.collection.loadedAll,
      // @ts-expect-error - Backbone View property
      count: this.collection.length,
      ENV,
    }
  }

  remove() {
    // @ts-expect-error - Backbone View property
    if (this.assignToGroupMenu != null) {
      // @ts-expect-error - Backbone View property
      this.assignToGroupMenu.remove()
    }
    return super.remove(...arguments)
  }

  // @ts-expect-error - Legacy Backbone typing
  focusAssignToGroup(e) {
    e.preventDefault()
    e.stopPropagation()
    const $target = $(e.currentTarget)
    // @ts-expect-error - Backbone View property
    this.fromAddButton = true
    const assignToGroupMenu = this._getAssignToGroup()
    // @ts-expect-error - Backbone View property
    assignToGroupMenu.model = this.collection.getUser($target.data('user-id'))
    return assignToGroupMenu.showBy($target, true)
  }

  // @ts-expect-error - Legacy Backbone typing
  showAssignToGroup(e) {
    // @ts-expect-error - Backbone View property
    if (this.elementIndex === -1) {
      e.preventDefault()
      e.stopPropagation()
    }
    const $target = $(e.currentTarget)

    const assignToGroupMenu = this._getAssignToGroup()
    // @ts-expect-error - Backbone View property
    assignToGroupMenu.model = this.collection.getUser($target.data('user-id'))
    return assignToGroupMenu.showBy($target)
  }

  _getAssignToGroup() {
    // @ts-expect-error - Backbone View property
    if (!this.assignToGroupMenu) {
      // @ts-expect-error - Backbone View property
      this.assignToGroupMenu = new AssignToGroupMenu({collection: this.groupsCollection})
      // @ts-expect-error - Backbone View property
      this.assignToGroupMenu.on(
        'open',
        // @ts-expect-error - Legacy Backbone typing
        options =>
          // @ts-expect-error - Backbone View property
          (this.elementIndex = Array.prototype.indexOf.apply(
            // @ts-expect-error - Backbone View property
            $('ul.collectionViewItems li.group-user', this.$el),
            // @ts-expect-error - Legacy Backbone typing
            $(options.target).parent('li'),
          )),
      )
      // @ts-expect-error - Backbone View property
      this.assignToGroupMenu.on('close', options => {
        // @ts-expect-error - Backbone View property
        const studentElements = $('li.group-user a.assign-to-group', this.$el)
        // @ts-expect-error - Backbone View property
        if (this.elementIndex !== -1) {
          if (studentElements.length === 0) {
            $('.filterable-unassigned-users').focus()
          } else if (options.escapePressed) {
            $(
              // @ts-expect-error - Backbone View property
              studentElements[this.elementIndex] || studentElements[studentElements.length - 1],
            ).focus()
          } else if (options.userMoved) {
            // @ts-expect-error - Backbone View property
            if (this.elementIndex === 0) {
              $('.filterable-unassigned-users').focus()
            } else {
              $(
                // @ts-expect-error - Backbone View property
                studentElements[this.elementIndex - 1] ||
                  studentElements[studentElements.length - 1],
              ).focus()
            }
          }
          // @ts-expect-error - Backbone View property
          return (this.elementIndex = -1)
        }
      })
    }
    // @ts-expect-error - Backbone View property
    return this.assignToGroupMenu
  }

  // @ts-expect-error - Legacy Backbone typing
  hideAssignToGroup(_e) {
    // @ts-expect-error - Backbone View property
    if (!this.fromAddButton) {
      // @ts-expect-error - Backbone View property
      if (this.assignToGroupMenu != null) {
        // @ts-expect-error - Backbone View property
        this.assignToGroupMenu.hide()
      }
      setTimeout(() => {
        // Element with next focus will not get focus until _after_ 'focusout' and 'blur' have been called.
        // @ts-expect-error - Backbone View property
        if (!this.$el.find('a.assign-to-group').is(':focus')) return (this.elementIndex = -1)
      }, 100)
    }
    // @ts-expect-error - Backbone View property
    return (this.fromAddButton = false)
  }

  // @ts-expect-error - Legacy Backbone typing
  setFilter(search_term, options) {
    // @ts-expect-error - Backbone View property
    const searchDefer = this.collection.search(search_term, options)
    if (searchDefer) {
      return searchDefer.always(() => {
        if (search_term.length < 3) {
          const shouldShow = search_term.length > 0
          // @ts-expect-error - Backbone View property
          this.$invalidFilter.toggleClass('hidden', !shouldShow)
          // @ts-expect-error - Backbone View property
          return this.$noResultsWrapper.toggle(shouldShow)
        }
      })
    }
  }

  canAssignToGroup() {
    // @ts-expect-error - Backbone View property
    return this.options.canAssignToGroup && this.groupsCollection.length
  }

  // #
  // handle drop events on '.unassigned-students'
  // ui.draggable: the user being dragged
  // @ts-expect-error - Legacy Backbone typing
  _onDrop(e, ui) {
    const user = ui.draggable.data('model')

    if (user.has('group') && groupHasSubmissions(user.get('group'))) {
      // @ts-expect-error - Backbone View property
      this.cloneCategoryView = new GroupCategoryCloneView({
        // @ts-expect-error - Backbone View property
        model: this.collection.category,
        openedFromCaution: true,
      })
      // @ts-expect-error - Backbone View property
      this.cloneCategoryView.open()
      // @ts-expect-error - Backbone View property
      return this.cloneCategoryView.on('close', () => {
        // @ts-expect-error - Backbone View property
        if (this.cloneCategoryView.cloneSuccess) {
          return window.location.reload()
          // @ts-expect-error - Backbone View property
        } else if (this.cloneCategoryView.changeGroups) {
          return this.moveUser(user)
        }
      })
    } else {
      return this.moveUser(user)
    }
  }

  // @ts-expect-error - Legacy Backbone typing
  moveUser(user) {
    // @ts-expect-error - Backbone View property
    return setTimeout(() => this.category.reassignUser(user, null))
  }

  // @ts-expect-error - Legacy Backbone typing
  _initDrag(view) {
    // @ts-expect-error - Legacy Backbone typing
    super._initDrag(...arguments)
    // @ts-expect-error - Backbone View property
    return view.$el.on('dragstart', (_event, _ui) => (this.elementIndex = -1))
  }
}
UnassignedUsersView.initClass()
