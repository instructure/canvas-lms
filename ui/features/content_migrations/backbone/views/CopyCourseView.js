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
import template from '../../jst/CopyCourse.handlebars'
import MigrationView from '@canvas/content-migrations/backbone/views/MigrationView'

extend(CopyCourseView, MigrationView)

function CopyCourseView() {
  return CopyCourseView.__super__.constructor.apply(this, arguments)
}

CopyCourseView.prototype.template = template

CopyCourseView.child('courseFindSelect', '.courseFindSelect')

CopyCourseView.child('dateShift', '.dateShift')

CopyCourseView.child('selectContent', '.selectContent')

CopyCourseView.child('importQuizzesNext', '.importQuizzesNext')

CopyCourseView.prototype.initialize = function () {
  CopyCourseView.__super__.initialize.apply(this, arguments)
  return this.courseFindSelect.on(
    'course_changed',
    (function (_this) {
      return function (course) {
        _this.dateShift.updateNewDates(course)
        return _this.selectContent.courseSelected(course)
      }
    })(this)
  )
}

export default CopyCourseView
