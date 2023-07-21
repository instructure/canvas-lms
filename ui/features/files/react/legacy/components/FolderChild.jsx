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

import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import ReactDOM from 'react-dom'
import BackboneMixin from '@canvas/files/react/mixins/BackboneMixin'
import Folder from '@canvas/files/backbone/models/Folder'
import FocusStore from '../modules/FocusStore'
import classnames from 'classnames'
import '@canvas/rails-flash-notifications'

const I18n = useI18nScope('react_files')

export default {
  displayName: 'FolderChild',

  mixins: [BackboneMixin('model')],

  getInitialState() {
    return {
      editing: this.props.model.isNew(),
      hideKeyboardCheck: true,
      isSelected: this.props.isSelected,
    }
  },

  componentDidMount() {
    if (this.state.editing) this.focusNameInput()
  },

  startEditingName() {
    this.setState({editing: true}, this.focusNameInput)
  },

  focusPreviousElement() {
    if (this.previouslyFocusedElement != null) {
      this.previouslyFocusedElement.focus()
    }
    if (document.activeElement === this.previouslyFocusedElement) return
    this.focusNameLink()
  },

  focusNameInput() {
    // If the activeElement is currently the "body" that means they clicked on some type of cog to enable this state.
    // This is an edge case that ensures focus remains in context of whats being edited, in this case, the nameLink
    this.previouslyFocusedElement =
      document.activeElement.nodeName === 'BODY'
        ? ReactDOM.findDOMNode(this.refs.nameLink)
        : document.activeElement

    setTimeout(() => {
      const input = this.refs.newName
      if (input) {
        const ext = input.value.lastIndexOf('.')
        input.setSelectionRange(0, ext < 0 ? input.value.length : ext)
        input.focus()
      }
    }, 0)
  },

  focusNameLink() {
    setTimeout(() => {
      const ref = ReactDOM.findDOMNode(this.refs.nameLink)
      if (ref) ref.focus()
    }, 100)
  },

  saveNameEdit() {
    this.setState({editing: false}, this.focusNameLink)
    const newName = ReactDOM.findDOMNode(this.refs.newName).value
    return this.props.model.save(
      {name: newName},
      {
        success: () => {
          this.focusNameLink()
        },
        error: (model, response) => {
          if (response.status === 409)
            $.flashError(
              I18n.t('A file named %{itemName} already exists in this folder.', {itemName: newName})
            )
        },
      }
    )
  },

  cancelEditingName() {
    if (this.props.model.isNew()) this.props.model.collection.remove(this.props.model)
    this.setState({editing: false}, this.focusPreviousElement)
  },

  getAttributesForRootNode() {
    const classNameString = classnames({
      'ef-item-row': true,
      'ef-item-selected': this.props.isSelected,
      activeDragTarget: this.state.isActiveDragTarget,
    })

    const attrs = {
      onClick: this.props.toggleSelected,
      className: classNameString,
      role: 'row',
      'aria-selected': this.props.isSelected,
      draggable: !this.state.editing,
      ref: 'FolderChild',
      onDragStart: event => {
        if (!this.props.isSelected) {
          this.props.toggleSelected()
        }
        return this.props.dndOptions.onItemDragStart(event)
      },
    }

    if (this.props.model instanceof Folder && !this.props.model.get('for_submissions')) {
      const toggleActive = setActive => {
        if (this.state.isActiveDragTarget !== setActive)
          this.setState({isActiveDragTarget: setActive})
      }
      attrs.onDragEnter = attrs.onDragOver = event =>
        this.props.dndOptions.onItemDragEnterOrOver(event, toggleActive(true))

      attrs.onDragLeave = attrs.onDragEnd = event =>
        this.props.dndOptions.onItemDragLeaveOrEnd(event, toggleActive(false))

      attrs.onDrop = event =>
        this.props.dndOptions.onItemDrop(event, this.props.model, ({success}) => {
          toggleActive(false)
          if (success)
            ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.refs.FolderChild).parentNode)
        })
    }
    return attrs
  },

  checkForAccess(event) {
    if (this.props.model.get('locked_for_user')) {
      event.preventDefault()
      const message = I18n.t('This folder is currently locked and unavailable to view.')
      $.flashError(message)
      $.screenReaderFlashMessage(message)
      return false
    }
  },

  handleFileLinkClick() {
    FocusStore.setItemToFocus(ReactDOM.findDOMNode(this.refs.nameLink))
    return this.props.previewItem()
  },
}
