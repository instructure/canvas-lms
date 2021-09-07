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
import {StoreState, PacePlan} from '../../types'
import {connect} from 'react-redux'
import {getPacePlan} from '../../reducers/pace_plans'

interface StoreProps {
  readonly pacePlan: PacePlan
}

export const PacePlanTable: React.FC<StoreProps> = ({pacePlan}) => (
  <>
    {pacePlan.modules.map((module, index) => (
      <Module key={`module-${module.id}`} index={index + 1} module={module} pacePlan={pacePlan} />
    ))}
  </>
)

const mapStateToProps = (state: StoreState) => {
  return {
    pacePlan: getPacePlan(state)
  }
}

export default connect(mapStateToProps)(PacePlanTable)
