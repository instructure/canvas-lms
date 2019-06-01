/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

module.exports = {
  "presets": [
    ["@instructure/ui-babel-preset", {
      // this tells @babel/plugin-transform-runtime to not use ESModules in jest.
      esModules: !process.env.JEST_WORKER_ID,
      // this tells it to transform imports to commonJS in jest
      node: !!process.env.JEST_WORKER_ID
    }]
  ],
  "env": {
    "production": {
      "plugins": [
        "transform-react-remove-prop-types",
        "@babel/plugin-transform-react-inline-elements"
      ]
    }
  }
}
