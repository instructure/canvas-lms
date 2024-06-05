/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import OutcomeAlignmentDeleteLink from '../OutcomeAlignmentDeleteLink'

const renderOutcomeAlignmentDeleteLink = (props = {}) =>
  render(<OutcomeAlignmentDeleteLink {...props} />)

describe('OutcomeAlignmentDeleteLink', () => {
  it('should render span if hasRubricAssociation', () => {
    const {container} = renderOutcomeAlignmentDeleteLink({
      url: 'http://hellow',
      has_rubric_association: 'has_rubric_association',
    })

    expect(container.querySelector('a')).not.toBeInTheDocument()
    expect(
      screen.getByText(/Can't delete alignments based on rubric associations./)
    ).toBeInTheDocument()
  })

  it('should render a link if !hasRubricAssociation', () => {
    const {container} = renderOutcomeAlignmentDeleteLink({url: 'http://hellow'})

    expect(container.querySelector('a')).toBeInTheDocument()
    expect(screen.getByText('Delete alignment')).toBeInTheDocument()
  })
})
