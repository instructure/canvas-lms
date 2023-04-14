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
import template from '../../jst/MoodleZip.handlebars'
import MigrationView from '@canvas/content-migrations/backbone/views/MigrationView'

extend(MoodleZip, MigrationView)

function MoodleZip() {
  return MoodleZip.__super__.constructor.apply(this, arguments)
}

MoodleZip.prototype.template = template

MoodleZip.child('chooseMigrationFile', '.chooseMigrationFile')

MoodleZip.child('questionBank', '.selectQuestionBank')

MoodleZip.child('dateShift', '.dateShift')

MoodleZip.child('selectContent', '.selectContent')

export default MoodleZip
