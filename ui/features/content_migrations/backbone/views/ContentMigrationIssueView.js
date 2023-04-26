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

import template from '../../jst/ContentMigrationIssue.handlebars'

extend(ContentMigrationIssueView, Backbone.View)

function ContentMigrationIssueView() {
  return ContentMigrationIssueView.__super__.constructor.apply(this, arguments)
}

ContentMigrationIssueView.prototype.className = 'clearfix row-fluid top-padding'

ContentMigrationIssueView.prototype.template = template

ContentMigrationIssueView.prototype.tagName = 'li'

ContentMigrationIssueView.prototype.toJSON = function () {
  const json = ContentMigrationIssueView.__super__.toJSON.apply(this, arguments)
  json.description = this.model.get('description')
  json.fix_issue_url = this.model.get('fix_issue_html_url')
  return json
}

export default ContentMigrationIssueView
