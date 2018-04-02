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

// this is just https://github.com/usepropeller/react.backbone but without the UMD wrapper.

import Backbone from 'Backbone'
import _ from 'underscore'

const collectionBehavior = {
  changeOptions: 'add remove reset sort',
  updateScheduler(func) {
    return _.debounce(func, 0)
  }
}

const modelBehavior = {
  changeOptions: 'change',

  // note: if we debounce models too we can no longer use model attributes
  // as properties to react controlled components due to https://github.com/facebook/react/issues/955
  updateScheduler: _.identity
}

function subscribe(component, modelOrCollection, customChangeOptions) {
  if (!modelOrCollection) return
  const behavior =
    modelOrCollection instanceof Backbone.Collection ? collectionBehavior : modelBehavior
  const triggerUpdate = behavior.updateScheduler(function() {
    if (component.isMounted()) {
      return (component.onModelChange || component.forceUpdate).call(component)
    }
  })
  const changeOptions = customChangeOptions || component.changeOptions || behavior.changeOptions
  return modelOrCollection.on(changeOptions, triggerUpdate, component)
}

function unsubscribe(component, modelOrCollection) {
  if (!modelOrCollection) return
  return modelOrCollection.off(null, null, component)
}

export default function BackboneMixin(optionsOrPropName, customChangeOptions) {
  let modelOrCollection, propName
  if (typeof optionsOrPropName === 'object') {
    customChangeOptions = optionsOrPropName.renderOn
    ;({propName} = optionsOrPropName)
    ;({modelOrCollection} = optionsOrPropName)
  } else {
    propName = optionsOrPropName
  }
  if (!modelOrCollection) {
    modelOrCollection = props => props[propName]
  }

  return {
    componentDidMount() {
      // Whenever there may be a change in the Backbone data, trigger a reconcile.
      subscribe(this, modelOrCollection(this.props), customChangeOptions)
    },

    componentWillReceiveProps(nextProps) {
      if (modelOrCollection(this.props) === modelOrCollection(nextProps)) return
      unsubscribe(this, modelOrCollection(this.props))
      subscribe(this, modelOrCollection(nextProps), customChangeOptions)
      if (typeof this.componentWillChangeModel === 'function') this.componentWillChangeModel()
    },

    componentDidUpdate(prevProps, prevState) {
      if (modelOrCollection(this.props) === modelOrCollection(prevProps)) return
      if (typeof this.componentDidChangeModel === 'function') this.componentDidChangeModel()
    },

    componentWillUnmount() {
      // Ensure that we clean up any dangling references when the component is destroyed.
      unsubscribe(this, modelOrCollection(this.props))
    }
  }
}
