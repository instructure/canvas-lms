/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import userEvent from '@testing-library/user-event'
import {AIAnalysisTab} from '../AIAnalysisTab'
import type {ConversationEvaluation} from '../../../types'

describe('AIAnalysisTab', () => {
  const mockEvaluation: ConversationEvaluation = {
    overall_assessment: 'Student demonstrated strong analytical skills and good understanding.',
    key_moments: [
      {
        learning_objective: 'Critical thinking',
        evidence: 'Student analyzed the problem systematically',
        message_number: 3,
      },
    ],
    learning_objectives_evaluation: [
      {
        objective: 'Critical thinking',
        met: true,
        score: 85,
        explanation: 'Student showed excellent analytical skills',
      },
      {
        objective: 'Historical context',
        met: false,
        score: 45,
        explanation: 'Student needs more practice with historical analysis',
      },
    ],
    strengths: ['Clear communication', 'Systematic approach', 'Good problem-solving skills'],
    areas_for_improvement: ['Historical context analysis', 'Evidence citation'],
    overall_score: 85,
  }

  const mockOnRequestEvaluation = jest.fn()

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('shows empty state when no evaluation is provided', () => {
    render(
      <AIAnalysisTab
        evaluation={null}
        isLoading={false}
        error={null}
        onRequestEvaluation={mockOnRequestEvaluation}
      />,
    )

    expect(screen.getByText(/No evaluation data available yet/i)).toBeInTheDocument()
    expect(screen.getByText(/Click "Request Evaluation" to analyze/i)).toBeInTheDocument()
  })

  it('calls onRequestEvaluation when button is clicked in empty state', async () => {
    const user = userEvent.setup()
    render(
      <AIAnalysisTab
        evaluation={null}
        isLoading={false}
        error={null}
        onRequestEvaluation={mockOnRequestEvaluation}
      />,
    )

    const buttons = screen.getAllByText('Request Evaluation')
    const button = buttons.find(el => el.closest('button'))?.closest('button')
    if (!button) throw new Error('Button not found')
    await user.click(button)

    expect(mockOnRequestEvaluation).toHaveBeenCalledTimes(1)
  })

  it('shows loading state', () => {
    render(
      <AIAnalysisTab
        evaluation={null}
        isLoading={true}
        error={null}
        onRequestEvaluation={mockOnRequestEvaluation}
      />,
    )

    const loadingTexts = screen.getAllByText(/Evaluating conversation.../i)
    expect(loadingTexts.length).toBeGreaterThan(0)
  })

  it('shows error state with error message', () => {
    render(
      <AIAnalysisTab
        evaluation={null}
        isLoading={false}
        error="Service temporarily unavailable"
        onRequestEvaluation={mockOnRequestEvaluation}
      />,
    )

    expect(screen.getByText(/Error: Service temporarily unavailable/i)).toBeInTheDocument()
    expect(screen.getByText(/Retry Evaluation/i)).toBeInTheDocument()
  })

  it('calls onRequestEvaluation when retry button is clicked', async () => {
    const user = userEvent.setup()
    render(
      <AIAnalysisTab
        evaluation={null}
        isLoading={false}
        error="Service error"
        onRequestEvaluation={mockOnRequestEvaluation}
      />,
    )

    const retryText = screen.getByText('Retry Evaluation')
    const retryButton = retryText.closest('button')
    if (!retryButton) throw new Error('Retry button not found')
    await user.click(retryButton)

    expect(mockOnRequestEvaluation).toHaveBeenCalledTimes(1)
  })

  it('displays evaluation results correctly', () => {
    render(
      <AIAnalysisTab
        evaluation={mockEvaluation}
        isLoading={false}
        error={null}
        onRequestEvaluation={mockOnRequestEvaluation}
      />,
    )

    // Check header and overall score
    expect(screen.getByText(/AI Analysis/i)).toBeInTheDocument()
    expect(screen.getByText('85/100')).toBeInTheDocument()
    expect(screen.getByText(/Overall Score/i)).toBeInTheDocument()

    // Check learning objectives (1 out of 2 met in mock data)
    expect(screen.getByText('1/2')).toBeInTheDocument()
    const learningObjectivesElements = screen.getAllByText(/Learning Objectives/i)
    expect(learningObjectivesElements.length).toBeGreaterThan(0)

    // Check performance level
    expect(screen.getByText(/Meets/i)).toBeInTheDocument()
  })

  it('displays learning objectives detail correctly', () => {
    render(
      <AIAnalysisTab
        evaluation={mockEvaluation}
        isLoading={false}
        error={null}
        onRequestEvaluation={mockOnRequestEvaluation}
      />,
    )

    // Check that both objectives are displayed (using getAllByText since "Historical context" appears in multiple places)
    expect(screen.getByText(/Critical thinking/i)).toBeInTheDocument()
    const historicalContextElements = screen.getAllByText(/Historical context/i)
    expect(historicalContextElements.length).toBeGreaterThan(0)

    // Check explanations
    expect(screen.getByText(/excellent analytical skills/i)).toBeInTheDocument()
    expect(screen.getByText(/needs more practice/i)).toBeInTheDocument()
  })

  it('displays strengths section', () => {
    render(
      <AIAnalysisTab
        evaluation={mockEvaluation}
        isLoading={false}
        error={null}
        onRequestEvaluation={mockOnRequestEvaluation}
      />,
    )

    expect(screen.getByText(/Key Strengths/i)).toBeInTheDocument()
    expect(screen.getByText('Clear communication')).toBeInTheDocument()
    expect(screen.getByText('Systematic approach')).toBeInTheDocument()
    expect(screen.getByText('Good problem-solving skills')).toBeInTheDocument()
  })

  it('displays areas for improvement section', () => {
    render(
      <AIAnalysisTab
        evaluation={mockEvaluation}
        isLoading={false}
        error={null}
        onRequestEvaluation={mockOnRequestEvaluation}
      />,
    )

    expect(screen.getByText(/Areas for Improvement/i)).toBeInTheDocument()
    expect(screen.getByText('Historical context analysis')).toBeInTheDocument()
    expect(screen.getByText('Evidence citation')).toBeInTheDocument()
  })

  it('displays AI feedback summary', () => {
    render(
      <AIAnalysisTab
        evaluation={mockEvaluation}
        isLoading={false}
        error={null}
        onRequestEvaluation={mockOnRequestEvaluation}
      />,
    )

    expect(screen.getByText(/AI Feedback Summary/i)).toBeInTheDocument()
    expect(screen.getByText(/Student demonstrated strong analytical skills/i)).toBeInTheDocument()
  })

  it('shows Re-evaluate button when evaluation is present', () => {
    render(
      <AIAnalysisTab
        evaluation={mockEvaluation}
        isLoading={false}
        error={null}
        onRequestEvaluation={mockOnRequestEvaluation}
      />,
    )

    expect(screen.getByText(/Re-evaluate/i)).toBeInTheDocument()
  })

  it('calls onRequestEvaluation when re-evaluate button is clicked', async () => {
    const user = userEvent.setup()
    render(
      <AIAnalysisTab
        evaluation={mockEvaluation}
        isLoading={false}
        error={null}
        onRequestEvaluation={mockOnRequestEvaluation}
      />,
    )

    const buttonText = screen.getByText('Re-evaluate')
    const button = buttonText.closest('button')
    if (!button) throw new Error('Re-evaluate button not found')
    await user.click(button)

    expect(mockOnRequestEvaluation).toHaveBeenCalledTimes(1)
  })

  it('displays student name in header when provided', () => {
    render(
      <AIAnalysisTab
        studentName="John Doe"
        evaluation={mockEvaluation}
        isLoading={false}
        error={null}
        onRequestEvaluation={mockOnRequestEvaluation}
      />,
    )

    expect(screen.getByText(/AI Analysis for John Doe/i)).toBeInTheDocument()
  })

  it('does not show strengths section when empty', () => {
    const evaluationWithoutStrengths = {...mockEvaluation, strengths: []}

    render(
      <AIAnalysisTab
        evaluation={evaluationWithoutStrengths}
        isLoading={false}
        error={null}
        onRequestEvaluation={mockOnRequestEvaluation}
      />,
    )

    expect(screen.queryByText(/Key Strengths/i)).not.toBeInTheDocument()
  })

  it('does not show areas for improvement section when empty', () => {
    const evaluationWithoutImprovements = {...mockEvaluation, areas_for_improvement: []}

    render(
      <AIAnalysisTab
        evaluation={evaluationWithoutImprovements}
        isLoading={false}
        error={null}
        onRequestEvaluation={mockOnRequestEvaluation}
      />,
    )

    expect(screen.queryByText(/Areas for Improvement/i)).not.toBeInTheDocument()
  })

  it('displays correct performance level for high scores', () => {
    const highScoreEvaluation = {...mockEvaluation, overall_score: 95}

    render(
      <AIAnalysisTab
        evaluation={highScoreEvaluation}
        isLoading={false}
        error={null}
        onRequestEvaluation={mockOnRequestEvaluation}
      />,
    )

    expect(screen.getByText(/Exceeds/i)).toBeInTheDocument()
  })

  it('displays correct performance level for low scores', () => {
    const lowScoreEvaluation = {...mockEvaluation, overall_score: 35}

    render(
      <AIAnalysisTab
        evaluation={lowScoreEvaluation}
        isLoading={false}
        error={null}
        onRequestEvaluation={mockOnRequestEvaluation}
      />,
    )

    expect(screen.getByText(/Below/i)).toBeInTheDocument()
  })

  it('displays correct performance level for approaching scores', () => {
    const approachingEvaluation = {...mockEvaluation, overall_score: 55}

    render(
      <AIAnalysisTab
        evaluation={approachingEvaluation}
        isLoading={false}
        error={null}
        onRequestEvaluation={mockOnRequestEvaluation}
      />,
    )

    expect(screen.getByText(/Approaches/i)).toBeInTheDocument()
  })
})
