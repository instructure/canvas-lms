/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import $ from 'jquery'
import {configure, mount} from './react/index'
import ready from '@instructure/ready'

ready(() => {
  configure({
    ajax: $.ajax,
    loadOnStartup: true,
    quizUrl: ENV.quiz_url,
    questionsUrl: ENV.questions_url,
    submissionUrl: ENV.submission_url,
    eventsUrl: ENV.events_url,
    allowMatrixView: ENV.can_view_answer_audits,
  })

  mount(document.body.querySelector('#content')).then(() =>
    console.log('Yeah, a canvas quiz app has been loaded!!!')
  )
})
