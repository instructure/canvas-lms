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

import React from 'react'

import Module from './module'
import {CoursePace, ResponsiveSizes, StoreState} from '../../types'
import {connect} from 'react-redux'
import {getCoursePace, getCompression} from '../../reducers/course_paces'
import {getResponsiveSize, getShowProjections} from '../../reducers/ui'

interface StoreProps {
  readonly coursePace: CoursePace
  readonly responsiveSize: ResponsiveSizes
  readonly showProjections: boolean
  readonly compression: number
}

export const CoursePaceTable: React.FC<StoreProps> = ({
  coursePace,
  responsiveSize,
  showProjections,
  compression
}) => (
  <>
    {coursePace.modules.map((module, index) => (
      <Module
        key={`module-${module.id}`}
        index={index + 1}
        module={module}
        coursePace={coursePace}
        responsiveSize={responsiveSize}
        showProjections={showProjections}
        compression={compression}
      />
    ))}
  </>
)

const mapStateToProps = (state: StoreState) => {
  return {
    coursePace: getCoursePace(state),
    responsiveSize: getResponsiveSize(state),
    showProjections: getShowProjections(state),
    compression: getCompression(state)
  }
}

export default connect(mapStateToProps)(CoursePaceTable)
