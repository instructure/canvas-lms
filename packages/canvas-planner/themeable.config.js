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

/*
this file is just here so we can have it not put componentId in the css
selectors it in the jest snapshots. so we don't get snapshot changes for
random css changes. otherwise, we could just delete this file and have it do
the default
*/
module.exports = {
  generateScopedName({env}, componentId) {
    // for css modules class names
    const env2 = process.env.NODE_ENV || env // because what sets the env arg prefers BABEL_ENV over NODE_ENV
    return env2 === 'production' ? `${componentId}_[hash:base64:4]` : '[folder]-[name]__[local]'
  }
}
