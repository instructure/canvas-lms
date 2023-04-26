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
import template from '../../jst/SourceLink.handlebars'

extend(SourceLinkView, Backbone.View)

function SourceLinkView() {
  return SourceLinkView.__super__.constructor.apply(this, arguments)
}

SourceLinkView.prototype.template = template

SourceLinkView.prototype.toJSON = function () {
  const json = SourceLinkView.__super__.toJSON.apply(this, arguments)
  json.attachment = this.model.get('attachment')
  json.settings = this.model.get('settings')
  return json
}

export default SourceLinkView
