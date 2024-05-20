/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {extend} from 'lodash'
import config from './config'
import controller from './controller'
import initialize from './config/initializer'
import Layout from './react/components/app'
import React from 'react'
import ReactDOM from 'react-dom'

let container

/**
 * Configure the application. See Config for the supported options.
 *
 * @param  {Object} options
 *         A set of options to override.
 */
export const configure = function (options) {
  extend(config, options)
}

/**
 * Start the app and perform any necessary data loading.
 *
 * @param  {HTMLElement} node
 *         The node to mount the app in.
 *
 * @param  {Object} [options={}]
 *         Options to configure the app with. See config.js
 *
 * @return {Promise}
 *         Fulfilled when the app has been started and rendered.
 */
export const mount = function (node, options) {
  configure(options)
  container = node

  return initialize().then(function () {
    ReactDOM.render(<Layout />, container)
    return controller.start(update)
  })
}

export const isMounted = () => !!container

export const update = props => {
  ReactDOM.render(<Layout {...props} />, container)
}

export const reload = () => controller.load()

export const unmount = function () {
  if (isMounted()) {
    controller.stop()
    ReactDOM.unmountComponentAtNode(container)
    container = undefined
  }
}