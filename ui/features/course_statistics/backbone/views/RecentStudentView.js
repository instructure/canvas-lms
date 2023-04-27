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
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import Backbone from '@canvas/backbone'
import RecentStudentTemplate from '../../jst/recentStudent.handlebars'

const I18n = useI18nScope('course_statistics')

extend(RecentStudentView, Backbone.View)

function RecentStudentView() {
  return RecentStudentView.__super__.constructor.apply(this, arguments)
}

RecentStudentView.prototype.tagName = 'li'

RecentStudentView.prototype.template = RecentStudentTemplate

RecentStudentView.prototype.toJSON = function () {
  const data = this.model.toJSON()
  if (data.last_login != null) {
    const date = $.fudgeDateForProfileTimezone(new Date(data.last_login))
    data.last_login = I18n.t('#time.event', '%{date} at %{time}', {
      date: I18n.l('#date.formats.short', date),
      time: I18n.l('#time.formats.tiny', date),
    })
  } else {
    data.last_login = I18n.t('unknown', 'unknown')
  }
  return data
}

export default RecentStudentView
