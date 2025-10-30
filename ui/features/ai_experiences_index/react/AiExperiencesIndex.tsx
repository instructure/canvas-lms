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
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {Button} from '@instructure/ui-buttons'
import {IconAddLine} from '@instructure/ui-icons'
import AIExperienceList from './components/AIExperienceList'
import AIExperiencesEmptyState from './components/AIExperiencesEmptyState'
import type {AiExperience} from './types'

const AiExperiencesIndex: React.FC = () => {
  const I18n = useI18nScope('ai_experiences')
  const [experiences, setExperiences] = useState<AiExperience[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchExperiences = async () => {
      try {
        const courseId = ENV.COURSE_ID

        if (!courseId) {
          throw new Error('Could not find course ID in environment')
        }

        const response = await fetch(`/courses/${courseId}/ai_experiences`, {
          headers: {
            Accept: 'application/json',
          },
        })

        if (!response.ok) {
          throw new Error('Failed to fetch AI experiences')
        }

        const data = await response.json()
        setExperiences(data)
      } catch (err) {
        // TODO: Show flash alert to user for fetch error
        setError(err instanceof Error ? err.message : 'An error occurred')
      } finally {
        setLoading(false)
      }
    }

    fetchExperiences()
  }, [])

  const handleEdit = (id: number) => {
    const courseId = ENV.COURSE_ID
    window.location.href = `/courses/${courseId}/ai_experiences/${id}/edit`
  }

  const handleTestConversation = (id: number) => {
    const courseId = ENV.COURSE_ID
    window.location.href = `/courses/${courseId}/ai_experiences/${id}?preview=true`
  }

  const handleDelete = async (id: number) => {
    if (
      !window.confirm(
        I18n.t('Are you sure you want to delete this AI Experience? This action cannot be undone.'),
      )
    ) {
      return
    }

    try {
      const courseId = ENV.COURSE_ID

      const response = await fetch(`/courses/${courseId}/ai_experiences/${id}`, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
        },
      })

      if (!response.ok) {
        throw new Error('Failed to delete AI experience')
      }

      // Remove from local state
      setExperiences(prevExperiences => prevExperiences.filter(exp => exp.id !== id))
    } catch (err) {
      // TODO: Replace alert() with flash alert
      alert(I18n.t('Failed to delete AI Experience. Please try again.'))
    }
  }

  const handlePublishToggle = async (id: number, newState: 'published' | 'unpublished') => {
    try {
      const courseId = ENV.COURSE_ID

      const response = await fetch(`/courses/${courseId}/ai_experiences/${id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
        },
        body: JSON.stringify({
          ai_experience: {
            workflow_state: newState,
          },
        }),
      })

      if (!response.ok) {
        throw new Error('Failed to update AI experience')
      }

      const updatedExperience = await response.json()

      // Update the local state
      setExperiences(prevExperiences =>
        prevExperiences.map(exp => (exp.id === id ? {...exp, workflow_state: newState} : exp)),
      )
    } catch (err) {
      // TODO: Show flash alert to user for publish/unpublish error
    }
  }

  const handleCreateNew = () => {
    const courseId = ENV.COURSE_ID
    window.location.href = `/courses/${courseId}/ai_experiences/new`
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
        <Flex justifyItems="space-between" alignItems="center">
          <Flex.Item>
            <Heading level="h1">{I18n.t('AI Experiences')}</Heading>
          </Flex.Item>
          {experiences.length > 0 && (
            <Flex.Item>
              <Button
                data-testid="ai-expriences-index-create-new-button"
                color="primary"
                renderIcon={() => <IconAddLine />}
                onClick={handleCreateNew}
              >
                {I18n.t('Create new')}
              </Button>
            </Flex.Item>
          )}
        </Flex>
      </View>

      {experiences.length === 0 ? (
        <AIExperiencesEmptyState onCreateNew={handleCreateNew} />
      ) : (
        <AIExperienceList
          experiences={experiences}
          onEdit={handleEdit}
          onTestConversation={handleTestConversation}
          onPublishToggle={handlePublishToggle}
          onDelete={handleDelete}
        />
      )}
    </View>
  )
}

export default AiExperiencesIndex
