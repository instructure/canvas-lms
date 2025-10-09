/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import React, {useEffect, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import AIExperienceRow from './components/AIExperienceRow'

interface AiExperience {
  id: number
  title: string
  description?: string
  workflow_state: 'published' | 'unpublished'
  facts?: string
  learning_objective?: string
  scenario?: string
}

const AiExperiencesIndex: React.FC = () => {
  const I18n = useI18nScope('ai_experiences')
  const [experiences, setExperiences] = useState<AiExperience[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchExperiences = async () => {
      try {
        // Get course ID from URL path since ENV might not have it
        const courseId = window.location.pathname.match(/\/courses\/(\d+)/)?.[1]

        if (!courseId) {
          throw new Error('Could not find course ID in URL')
        }

        console.log('Fetching AI experiences for course:', courseId)
        const response = await fetch(`/courses/${courseId}/ai_experiences`, {
          headers: {
            Accept: 'application/json',
          },
        })

        if (!response.ok) {
          throw new Error('Failed to fetch AI experiences')
        }

        const data = await response.json()
        console.log('AI experiences loaded:', data)
        setExperiences(data)
      } catch (err) {
        console.error('Error fetching AI experiences:', err)
        setError(err instanceof Error ? err.message : 'An error occurred')
      } finally {
        setLoading(false)
      }
    }

    fetchExperiences()
  }, [])

  const handleEdit = (id: number) => {
    const courseId = window.location.pathname.match(/\/courses\/(\d+)/)?.[1]
    window.location.href = `/courses/${courseId}/ai_experiences/${id}/edit`
  }

  const handleTestConversation = (id: number) => {
    console.log('Test conversation for AI experience:', id)
  }

  const handlePublishToggle = async (id: number, newState: 'published' | 'unpublished') => {
    try {
      const courseId = window.location.pathname.match(/\/courses\/(\d+)/)?.[1]

      console.log(`API call: Updating AI experience ${id} to ${newState}`)

      const response = await fetch(`/courses/${courseId}/ai_experiences/${id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
        },
        body: JSON.stringify({
          workflow_state: newState,
        }),
      })

      if (!response.ok) {
        throw new Error('Failed to update AI experience')
      }

      const updatedExperience = await response.json()
      console.log('AI experience updated successfully:', updatedExperience)

      // Update the local state
      setExperiences(prevExperiences =>
        prevExperiences.map(exp => (exp.id === id ? {...exp, workflow_state: newState} : exp)),
      )
    } catch (err) {
      console.error('Error updating AI experience:', err)
    }
  }

  if (loading) {
    return (
      <View as="div" textAlign="center" margin="large">
        <Spinner renderTitle={I18n.t('Loading AI experiences')} />
      </View>
    )
  }

  if (error) {
    return (
      <View as="div" margin="medium">
        <Text color="danger">{I18n.t('Error loading AI experiences: %{error}', {error})}</Text>
      </View>
    )
  }

  return (
    <View as="div" margin="medium">
      <View as="div" margin="0 0 medium 0">
        <Heading level="h1">{I18n.t('AI Experiences')}</Heading>
      </View>

      {experiences.length === 0 ? (
        <View as="div" textAlign="center" margin="large">
          <Text size="large">{I18n.t('No AI experiences found')}</Text>
          <View as="div" margin="medium 0 0 0">
            <Text size="medium" color="secondary">
              {I18n.t('Create your first AI experience to get started')}
            </Text>
          </View>
        </View>
      ) : (
        <View as="div">
          {experiences.map(experience => (
            <AIExperienceRow
              key={experience.id}
              id={experience.id}
              title={experience.title}
              workflowState={experience.workflow_state}
              experienceType="LLM Conversation"
              onEdit={handleEdit}
              onTestConversation={handleTestConversation}
              onPublishToggle={handlePublishToggle}
            />
          ))}
        </View>
      )}
    </View>
  )
}

export default AiExperiencesIndex
