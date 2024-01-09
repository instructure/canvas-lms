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

import React, {useEffect} from 'react'
import {useMatch} from 'react-router-dom'
import {PortfolioDashboard} from '../../components/learner/Portfolios'

export function Component() {
  const pathMatch = useMatch('/users/:userId/*')
  if (!pathMatch || !pathMatch.params || !pathMatch.params.userId) {
    throw new Error('user id is not present on path')
  }

  useEffect(() => {
    document.title = 'Learner Passport: Portfolios'
  }, [])

  return <PortfolioDashboard />
}
