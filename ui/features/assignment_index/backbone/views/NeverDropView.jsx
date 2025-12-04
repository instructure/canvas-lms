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
import {defer} from 'es-toolkit/compat'
import Backbone from '@canvas/backbone'
import React from 'react'
import {createRoot} from 'react-dom/client'
import ReactDOM from 'react-dom'
import NeverDropComponent from '../../react/NeverDrop'

extend(NeverDrop, Backbone.View)

function NeverDrop() {
  this.renderReactComponent = this.renderReactComponent.bind(this)
  return NeverDrop.__super__.constructor.apply(this, arguments)
}

NeverDrop.optionProperty('canChangeDropRules')

NeverDrop.prototype.render = function () {
  this.renderReactComponent()
  return this
}

NeverDrop.prototype.renderReactComponent = function () {
  if (!this.reactRoot) {
    this.reactRoot = createRoot(this.el)
  }

  const modelData = this.model.toJSON()
  const props = {
    canChangeDropRules: this.canChangeDropRules,
    chosen: modelData.chosen,
    chosen_id: modelData.chosen_id,
    label_id: this.model.get('label_id'),
    assignments: this.model.has('chosen_id')
      ? this.model.collection.toAssignments(this.model.get('chosen_id'))
      : [],
    onRemove: () => {
      if (this.canChangeDropRules) {
        this.model.collection.remove(this.model)
      }
    },
    onChange: chosenId => {
      if (this.canChangeDropRules) {
        this.model.set({
          chosen_id: chosenId,
          focus: true,
        })
      }
    },
  }

  ReactDOM.flushSync(() => {
    this.reactRoot.render(<NeverDropComponent {...props} />)
  })

  if (this.model.has('focus')) {
    defer(() => {
      this.$('select').focus()
      this.model.unset('focus')
    })
  }
}

NeverDrop.prototype.remove = function () {
  if (this.reactRoot) {
    this.reactRoot.unmount()
    this.reactRoot = null
  }
  return NeverDrop.__super__.remove.apply(this, arguments)
}

export default NeverDrop
