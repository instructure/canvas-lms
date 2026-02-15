/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import Essay from './answers/essay'
import FIMB from './answers/fill_in_multiple_blanks'
import Matching from './answers/matching'
import MultipleAnswers from './answers/multiple_answers'
import MultipleChoice from './answers/multiple_choice'
import MultipleDropdowns from './answers/multiple_dropdowns'
import React from 'react'

const GenericRenderer = (props: any) => <div>{'' + props.answer}</div>
const Renderers: any[] = [Essay, FIMB, Matching, MultipleAnswers, MultipleChoice, MultipleDropdowns]

const getRenderer = (questionType: any) =>
  Renderers.find((entry: any) => entry.questionTypes.includes(questionType)) || GenericRenderer

const Answer = (props: any) => {
  const Renderer = getRenderer(props.question.questionType)

  return <Renderer {...props} />
}

export default Answer
