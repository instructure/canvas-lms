/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import Backbone from '@canvas/backbone'
import React from 'react'
import ReactDOM from 'react-dom'
import MasteryPathToggle from '../../react/MasteryPathToggle'

extend(MasteryPathToggleView, Backbone.View)

function MasteryPathToggleView() {
  this.getOverrides = this.getOverrides.bind(this)
  this.setNewOverridesCollection = this.setNewOverridesCollection.bind(this)
  this.render = this.render.bind(this)
  return MasteryPathToggleView.__super__.constructor.apply(this, arguments)
}

// =================
//   ui interaction
// =================
MasteryPathToggleView.prototype.render = function () {
  const div = this.$el[0]
  if (!div) {
    return
  }

  ReactDOM.render(
    React.createElement(MasteryPathToggle, {
      overrides: this.getOverrides(),
      onSync: this.setNewOverridesCollection
    }),
    div,
  )
}

// ==============================
//     syncing with react data
// ==============================

MasteryPathToggleView.prototype.setNewOverridesCollection = function (newOverrides) {
  if (newOverrides !== undefined) {
    this.model.overrides.reset(newOverrides)
    const onlyVisibleToOverrides = !this.model.overrides.containsDefaultDueDate()
    this.model.assignment.isOnlyVisibleToOverrides(onlyVisibleToOverrides)
    this.render()
  }
}

// =================
//    model info
// =================

MasteryPathToggleView.prototype.getOverrides = function () {
  return this.model.overrides.models.map(model => model.toJSON().assignment_override)
}

export default MasteryPathToggleView
