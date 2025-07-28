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

import React from 'react'
import {render, fireEvent, screen} from '@testing-library/react'
import {Editor, Frame} from '@craftjs/core'
import {KnowledgeCheckSection} from '../KnowledgeCheckSection'
import {type KnowledgeCheckSectionProps} from '../types'
import {testSupportedQuestion} from './testQuestions'

describe('KnowledgeCheckSection', () => {
  const renderSection = (
    props: Partial<KnowledgeCheckSectionProps> = {},
    enabled: boolean = true,
  ) => {
    return render(
      <Editor enabled={enabled} resolver={{KnowledgeCheckSection}}>
        <Frame>
          {/* @ts-expect-error */}
          <KnowledgeCheckSection {...props} />
        </Frame>
      </Editor>,
    )
  }

  it('renders without crashing', () => {
    renderSection()
    expect(screen.getByText('Check Your Knowledge')).toBeInTheDocument()
  })

  it('renders select question button when no question is selected', () => {
    renderSection()
    expect(screen.getByText('Select Quiz')).toBeInTheDocument()
  })

  it('renders question when a question is selected', () => {
    renderSection(testSupportedQuestion)
    expect(screen.getByText('Blue is better than Octopus?')).toBeInTheDocument()
  })

  it('opens modal to select quiz', () => {
    renderSection()
    fireEvent.click(screen.getByText('Select Quiz'))
    expect(screen.getByText('Select a Quiz')).toBeInTheDocument()
  })

  describe('enabled false', () => {
    it('shows feedback when the answer is correct', () => {
      renderSection(testSupportedQuestion, false)
      fireEvent.click(screen.getByText('True'))
      fireEvent.click(screen.getByText('Check'))
      expect(screen.getByText('This is correct!')).toBeInTheDocument()
    })

    it('shows feedback when the answer is incorrect', () => {
      renderSection(testSupportedQuestion, false)
      fireEvent.click(screen.getByText('False'))
      fireEvent.click(screen.getByText('Check'))
      expect(screen.getByText('Nope.')).toBeInTheDocument()
    })
  })
})
