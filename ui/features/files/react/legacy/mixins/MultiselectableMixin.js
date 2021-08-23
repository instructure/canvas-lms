/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import _ from 'underscore'
import $ from 'jquery'

// To use this, your view must implement a `selectables` method that
// returns an array of the things that are selectable.
export default {
  getInitialState() {
    return {selectedItems: []}
  },

  componentDidMount() {
    $(window).on('keydown', this.handleCtrlPlusA)
  },

  componentWillUnmount() {
    $(window).off('keydown', this.handleCtrlPlusA)
  },

  // overwrite this in your component if you want to suppress the multi-select
  // behavior on different elements. Should be something you can pass to $.fn.is
  multiselectIgnoredElements: ':input:not(.multiselectable-toggler), a',

  handleCtrlPlusA(e) {
    let needle
    if (((needle = e.target.nodeName.toLowerCase()), ['input', 'textarea'].includes(needle))) {
      return
    }
    if (e.which === 65 && (e.ctrlKey || e.metaKey)) {
      e.preventDefault()
      return this.toggleAllSelected(!e.shiftKey)
    }
  }, // ctrl-shift-a

  toggleAllSelected(shouldSelect) {
    if (shouldSelect) {
      this.setState({selectedItems: this.selectables()})
    } else {
      this.setState({selectedItems: []})
    }
  },

  areAllItemsSelected() {
    return (
      this.state.selectedItems.length &&
      this.state.selectedItems.length === this.selectables().length
    )
  },

  selectRange(item) {
    const selectables = this.selectables()
    const newPos = selectables.indexOf(item)
    const lastPos = selectables.indexOf(_.last(this.state.selectedItems))
    const range = selectables.slice(Math.min(newPos, lastPos), Math.max(newPos, lastPos) + 1)
    // the anchor needs to stay at the end
    if (newPos > lastPos) {
      range.reverse()
    }
    this.setState({selectedItems: range})
  },

  clearSelectedItems(cb) {
    this.setState({selectedItems: []}, () => (typeof cb === 'function' ? cb() : undefined))
  },

  toggleItemSelected(item, event, cb) {
    let selectedItems
    if (event && $(event.target).closest(this.multiselectIgnoredElements).length) return

    if (event != null ? event.shiftKey : undefined) return this.selectRange(item)

    const itemIsSelected = this.state.selectedItems.includes(item)
    const leaveOthersAlone =
      (event && event.metaKey) ||
      (event && event.ctrlKey) ||
      (event && event.target.type) === 'checkbox'

    if (leaveOthersAlone && itemIsSelected) {
      selectedItems = _.without(this.state.selectedItems, item)
    } else if (leaveOthersAlone) {
      selectedItems = this.state.selectedItems.slice() // .slice() is to not mutate state directly
      selectedItems.push(item)
    } else if (itemIsSelected) {
      selectedItems = []
    } else {
      selectedItems = [item]
    }

    return this.setState({selectedItems}, () => (typeof cb === 'function' ? cb() : undefined))
  }
}
