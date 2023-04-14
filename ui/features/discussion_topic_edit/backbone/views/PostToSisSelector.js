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
import Backbone from '@canvas/backbone'
import template from '../../jst/PostToSisSelector.handlebars'
import '@canvas/assignments/jquery/toggleAccessibly'

const POST_TO_SIS = '#assignment_post_to_sis'

extend(PostToSisSelector, Backbone.View)

function PostToSisSelector() {
  this.toJSON = this.toJSON.bind(this)
  return PostToSisSelector.__super__.constructor.apply(this, arguments)
}

PostToSisSelector.prototype.template = template

PostToSisSelector.prototype.els = (function () {
  const els = {}
  els[POST_TO_SIS] = '$postToSis'
  return els
})()

PostToSisSelector.optionProperty('parentModel')

PostToSisSelector.optionProperty('nested')

PostToSisSelector.prototype.toJSON = function () {
  return {
    postToSIS: this.parentModel.postToSIS(),
    postToSISName: this.parentModel.postToSISName(),
    nested: this.nested,
    // eslint-disable-next-line no-void
    prefix: this.nested ? 'assignment' : void 0,
  }
}

export default PostToSisSelector
