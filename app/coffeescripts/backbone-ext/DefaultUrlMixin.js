//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import splitAssetString from '../str/splitAssetString'
// #
// In the spirit of convention over configuration, if the base API route of
// your model follows canvas's default routing pattern of:
// /api/v1/<context_type>/<context_id>/<plural_form_of_resource_name> then
// you can just define a `resourceName` property on your model or collection
// and fall back on this default 'url' function.  This will look for a
// @contextCode on your collection and fall back to
// ENV.context_asset_string.
//
// So, for example say you are on /courses/1 and you do new
// DiscussionTopicsCollection().fetch() it will go to
// /api/v1/courses/1/discussion_topics (since ENV.context_asset_string will
// be already set)
export default {
  _contextPath () {
    const assetString = this.contextAssetString || ENV.context_asset_string
    const [contextType, contextId] = splitAssetString(assetString)
    return `${encodeURIComponent(contextType)}/${encodeURIComponent(contextId)}`
  },

  _defaultUrl () {
    const resourceName = this.resourceName || this.model.prototype.resourceName
    if (!resourceName) {
      throw new Error('Must define a `resourceName` property on collection or model prototype to use defaultUrl')
    }
    return `/api/v1/${this._contextPath()}/${resourceName}`
  },
}
