/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

const {IgnorePlugin} = require('webpack')

const CONTEXT_COFFEESCRIPT_SPEC = 'spec/coffeescripts'
const CONTEXT_JSX_SPEC = 'spec/javascripts/jsx'
const UI_FEATURES_SPEC = 'ui/features'
const UI_SHARED_SPEC = 'ui/shared'

const QUNIT_SPEC = /Spec$/

exports.createPlugin = () => {
  return new IgnorePlugin({
    checkResource: (resource, context) => {
      return (
        QUNIT_SPEC.test(resource) &&
        (context.endsWith(CONTEXT_COFFEESCRIPT_SPEC) ||
          context.endsWith(UI_FEATURES_SPEC) ||
          context.endsWith(UI_SHARED_SPEC) ||
          context.endsWith(CONTEXT_JSX_SPEC))
      )
    },
  })
}

exports.CONTEXT_COFFEESCRIPT_SPEC = CONTEXT_COFFEESCRIPT_SPEC
exports.UI_FEATURES_SPEC = UI_FEATURES_SPEC
exports.UI_SHARED_SPEC = UI_SHARED_SPEC
exports.CONTEXT_JSX_SPEC = CONTEXT_JSX_SPEC
exports.QUNIT_SPEC = QUNIT_SPEC
