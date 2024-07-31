/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useEffect} from 'react'

import ConditionalRelease from './index'

type AssignmentGradingScheme = {
  A: number
  B: number
  C: number
  D: number
}

type Assignment = {
  id: string
  title: string
  description: string
  points_possible: number
  grading_type: string
  submission_types: string
  grading_scheme: AssignmentGradingScheme
}

type env = {
  assignment: Assignment
  course_id: string
  stats_url: string
}

type Props = {
  type: string
  env: env
}

export const MasteryPathsReactWrapper = (props: Props) => {
  useEffect(() => {
    if (document.querySelector('#conditional-release-target')) {
      ConditionalRelease.attach(
        document.querySelector('#conditional-release-target'),
        props.type,
        props.env
      )
    }
  }, [props.env, props.type])

  return <div id="conditional-release-target" />
}
