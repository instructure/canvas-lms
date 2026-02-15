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

import React from 'react'
import ReactDOM from 'react-dom'
import {extend} from 'es-toolkit/compat'
import config from './config'
import initialize from './config/initializers/initializer'
import Layout from './react/routes'
import controller from './controller'

interface ConfigOptions {
  ajax?: any
  loadOnStartup?: boolean
  quizUrl?: string
  questionsUrl?: string
  submissionUrl?: string
  eventsUrl?: string
  allowMatrixView?: boolean
  [key: string]: any
}

let container: HTMLElement | null = null

/**
 * Configure the application. See Config for the supported options.
 *
 * @param  {Object} options
 *         A set of options to override.
 */
export const configure = function (options: ConfigOptions): void {
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
export const mount = function (node: HTMLElement | null, options?: ConfigOptions): Promise<void> {
  if (options) {
    configure(options)
  }
  container = node

  return initialize().then(function () {
    if (container) {
      ReactDOM.render(<Layout {...controller.getState()} />, container)
    }
    return controller.start(update)
  })
}

export const isMounted = function (): boolean {
  return !!container
}

export const update = function (props: any): void {
  if (container) {
    ReactDOM.render(<Layout {...props} />, container)
  }
}

export const reload = function (): void {
  controller.load()
}

export const unmount = function (): void {
  if (isMounted()) {
    controller.stop()
    if (container) {
      ReactDOM.unmountComponentAtNode(container)
    }
    container = null
  }
}
