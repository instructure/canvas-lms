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
import template from '../../jst/CommonCartridge.handlebars'
import MigrationView from '@canvas/content-migrations/backbone/views/MigrationView'

extend(CommonCartridge, MigrationView)

function CommonCartridge() {
  return CommonCartridge.__super__.constructor.apply(this, arguments)
}

CommonCartridge.prototype.template = template

CommonCartridge.child('chooseMigrationFile', '.chooseMigrationFile')

CommonCartridge.child('questionBank', '.selectQuestionBank')

CommonCartridge.child('dateShift', '.dateShift')

CommonCartridge.child('selectContent', '.selectContent')

CommonCartridge.child('overwriteAssessmentContent', '.overwriteAssessmentContent')

CommonCartridge.child('importQuizzesNext', '.importQuizzesNext')

export default CommonCartridge
