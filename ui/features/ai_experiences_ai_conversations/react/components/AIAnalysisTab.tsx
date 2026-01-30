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
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {List} from '@instructure/ui-list'
import {Button} from '@instructure/ui-buttons'
import {Spinner} from '@instructure/ui-spinner'
import {Alert} from '@instructure/ui-alerts'
import {IconCheckSolid} from '@instructure/ui-icons'
import {ConversationEvaluation} from '../../types'

const I18n = createI18nScope('ai_experiences')

interface AIAnalysisTabProps {
  studentName?: string
  evaluation: ConversationEvaluation | null
  isLoading: boolean
  error: string | null
  onRequestEvaluation: () => void
}

// Helper to determine performance level from score
const getPerformanceLevel = (
  score: number,
): {label: string; color: 'primary' | 'secondary' | 'success' | 'danger' | 'warning'} => {
  if (score >= 90) return {label: I18n.t('Exceeds'), color: 'success'}
  if (score >= 70) return {label: I18n.t('Meets'), color: 'success'}
  if (score >= 50) return {label: I18n.t('Approaches'), color: 'warning'}
  return {label: I18n.t('Below'), color: 'danger'}
}

// Metric Card Component
interface MetricCardProps {
  value: string
  label: string
  description: string
  valueColor?: 'primary' | 'secondary' | 'success' | 'danger' | 'warning'
}

const MetricCard: React.FC<MetricCardProps> = ({value, label, description, valueColor}) => (
  <View
    as="div"
    padding="medium"
    background="secondary"
    borderRadius="medium"
    borderWidth="small"
    height="100%"
  >
    <Flex direction="column" gap="x-small">
      <Text size="x-large" weight="bold" color={valueColor}>
        {value}
      </Text>
      <Text weight="bold" size="small">
        {label}
      </Text>
      <Text size="x-small" color="secondary" lineHeight="condensed">
        {description}
      </Text>
    </Flex>
  </View>
)

export const AIAnalysisTab: React.FC<AIAnalysisTabProps> = ({
  studentName,
  evaluation,
  isLoading,
  error,
  onRequestEvaluation,
}) => {
  // Loading state
  if (isLoading) {
    return (
      <View as="div" padding="large" textAlign="center">
        <Spinner renderTitle={I18n.t('Evaluating conversation...')} />
        <View as="div" margin="small 0 0 0">
          <Text>{I18n.t('Evaluating conversation...')}</Text>
        </View>
      </View>
    )
  }

  // Error state
  if (error) {
    return (
      <View as="div" padding="large">
        <Alert variant="error" margin="0 0 medium 0">
          {I18n.t('Error: %{error}', {error})}
        </Alert>
        <Button onClick={onRequestEvaluation}>{I18n.t('Retry Evaluation')}</Button>
      </View>
    )
  }

  // Empty state
  if (!evaluation) {
    return (
      <View as="div" padding="large">
        <Flex direction="column" alignItems="center" gap="medium">
          <Text size="large" color="secondary">
            {I18n.t('No evaluation data available yet')}
          </Text>
          <Text color="secondary">
            {I18n.t('Click "Request Evaluation" to analyze this conversation')}
          </Text>
          <Button color="primary" onClick={onRequestEvaluation}>
            {I18n.t('Request Evaluation')}
          </Button>
        </Flex>
      </View>
    )
  }

  // Calculate metrics
  const metObjectives = evaluation.learning_objectives_evaluation.filter(obj => obj.met).length
  const totalObjectives = evaluation.learning_objectives_evaluation.length
  const performanceLevel = getPerformanceLevel(evaluation.overall_score)

  // Main evaluation display
  return (
    <View as="div" padding="large">
      <Flex direction="column" gap="large">
        {/* Header */}
        <Flex justifyItems="space-between" alignItems="center">
          <Heading level="h3">
            {studentName
              ? I18n.t('AI Analysis for %{studentName}', {studentName})
              : I18n.t('AI Analysis')}
          </Heading>
          <Button onClick={onRequestEvaluation}>{I18n.t('Re-evaluate')}</Button>
        </Flex>

        {/* Metrics Grid - Row 1 */}
        <Flex gap="small" wrap="wrap">
          <Flex.Item shouldGrow={true} size="25%">
            <MetricCard
              value={`${evaluation.overall_score}/100`}
              label={I18n.t('Overall Score')}
              description={I18n.t(
                'Combined score across all evaluation criteria and learning objectives',
              )}
            />
          </Flex.Item>
          <Flex.Item shouldGrow={true} size="25%">
            <MetricCard
              value={`${metObjectives}/${totalObjectives}`}
              label={I18n.t('Learning Objectives')}
              description={I18n.t('Number of learning objectives successfully met by the student')}
            />
          </Flex.Item>
          <Flex.Item shouldGrow={true} size="25%">
            <MetricCard
              value={performanceLevel.label}
              label={I18n.t('Performance Level')}
              description={I18n.t('Overall performance rating based on conversation quality')}
              valueColor={performanceLevel.color}
            />
          </Flex.Item>
        </Flex>

        {/* Learning Objectives Detail */}
        <View as="div">
          <Heading level="h4" margin="0 0 small 0">
            {I18n.t('Learning Objectives Detail')}
          </Heading>
          <List isUnstyled={true} margin="0">
            {evaluation.learning_objectives_evaluation.map((obj, index) => (
              <List.Item key={index} margin="0 0 small 0">
                <View as="div" padding="small" background="secondary" borderRadius="medium">
                  <Flex gap="small" alignItems="start">
                    <Flex.Item>
                      <Text weight="bold">
                        {obj.met ? '✓' : '✗'} {obj.objective}
                      </Text>
                      <Text size="small"> - {obj.score}/100</Text>
                    </Flex.Item>
                  </Flex>
                  <View as="div" margin="x-small 0 0 0">
                    <Text size="small">{obj.explanation}</Text>
                  </View>
                </View>
              </List.Item>
            ))}
          </List>
        </View>

        {/* Key Strengths */}
        {evaluation.strengths && evaluation.strengths.length > 0 && (
          <View as="div">
            <Heading level="h4" margin="0 0 small 0">
              {I18n.t('Key Strengths')}
            </Heading>
            <List isUnstyled={true} margin="0">
              {evaluation.strengths.map((strength, index) => (
                <List.Item key={index} margin="0 0 x-small 0">
                  <Flex gap="x-small" alignItems="start">
                    <View as="div" margin="xx-small 0 0 0">
                      <IconCheckSolid color="success" size="x-small" />
                    </View>
                    <Flex.Item shouldGrow={true}>
                      <Text>{strength}</Text>
                    </Flex.Item>
                  </Flex>
                </List.Item>
              ))}
            </List>
          </View>
        )}

        {/* Areas for Improvement */}
        {evaluation.areas_for_improvement && evaluation.areas_for_improvement.length > 0 && (
          <View as="div">
            <Heading level="h4" margin="0 0 small 0">
              {I18n.t('Areas for Improvement')}
            </Heading>
            <List margin="0">
              {evaluation.areas_for_improvement.map((area, index) => (
                <List.Item key={index}>{area}</List.Item>
              ))}
            </List>
          </View>
        )}

        {/* AI Feedback Summary */}
        <View as="div">
          <Heading level="h4" margin="0 0 small 0">
            {I18n.t('AI Feedback Summary')}
          </Heading>
          <View as="div" padding="small" background="secondary" borderRadius="medium">
            <Text>{evaluation.overall_assessment}</Text>
          </View>
        </View>
      </Flex>
    </View>
  )
}
