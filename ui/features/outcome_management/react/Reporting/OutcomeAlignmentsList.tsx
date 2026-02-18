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

import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {IconCheckMarkLine} from '@instructure/ui-icons'
import {getTagIcon, type ProficiencyRating} from '@canvas/outcomes/react/utils/icons'
import {getDescriptionForLevel} from '@canvas/outcomes/react/utils/masteryScaleLogic'
import type {MasteryLevel} from './types'
import MasteryDetail from './MasteryDetail'
import {useMemo, useEffect, useState} from 'react'
import type {ContributingScoresForOutcome} from '@canvas/outcomes/react/hooks/useContributingScores'
import useLMGBContext from '@canvas/outcomes/react/hooks/useLMGBContext'

const I18n = createI18nScope('outcome_management')

export interface AlignmentWithScore {
  alignmentId: string
  title: string
  type: string
  htmlUrl: string
  score: number | null
  submittedAt: string | null
  masteryLevel: MasteryLevel
}

interface OutcomeAlignmentsListProps {
  outcomeScores: ContributingScoresForOutcome
  studentId: string
  masteryPoints: number
  proficiencyRatings?: ProficiencyRating[]
  hasChartView?: boolean
}

const OutcomeAlignmentsList = ({
  outcomeScores,
  studentId,
  masteryPoints,
  proficiencyRatings: outcomeRatings,
  hasChartView = false,
}: OutcomeAlignmentsListProps) => {
  // Get proficiency ratings from props (outcome-specific), or fall back to context (global default)
  const {outcomeProficiency} = useLMGBContext()
  const proficiencyRatings: ProficiencyRating[] | undefined =
    outcomeRatings || outcomeProficiency?.ratings

  // Combine alignments with their scores for the list view
  const alignmentsWithScores: AlignmentWithScore[] = useMemo(() => {
    if (!outcomeScores.data) return []

    const userScores = outcomeScores.scoresForUser(studentId)
    const alignments = outcomeScores.alignments || []

    const combined: AlignmentWithScore[] = alignments.map((alignment, index) => {
      const score = userScores[index]
      const scoreValue = score?.score ?? null
      const masteryLevel = getTagIcon(scoreValue, masteryPoints, proficiencyRatings) as MasteryLevel

      return {
        alignmentId: alignment.alignment_id,
        title: alignment.associated_asset_name,
        type: alignment.associated_asset_type?.toLowerCase() || 'assignment',
        htmlUrl: alignment.html_url,
        score: scoreValue,
        submittedAt: score?.submitted_or_assessed_at ?? null,
        masteryLevel,
      }
    })

    // Sort by date ascending (oldest first), unassessed items at the end
    return combined.sort((a, b) => {
      if (!a.submittedAt && !b.submittedAt) return 0
      if (!a.submittedAt) return 1
      if (!b.submittedAt) return -1
      return new Date(a.submittedAt).getTime() - new Date(b.submittedAt).getTime()
    })
  }, [outcomeScores, studentId, masteryPoints, proficiencyRatings])

  // Load assignment type icons
  const [iconCache, setIconCache] = useState<Map<string, string>>(new Map())

  useEffect(() => {
    const loadIcons = async () => {
      const types = new Set(alignmentsWithScores.map(a => a.type))

      // Check which types need loading
      const typesToLoad = Array.from(types).filter(type => !iconCache.has(type))
      if (typesToLoad.length === 0) return

      // Load icons and collect results
      const loadPromises = typesToLoad.map(
        type =>
          new Promise<[string, string]>(resolve => {
            const img = new Image()
            img.src = `/images/outcomes/${type}.svg`
            img.onload = () => resolve([type, img.src])
            img.onerror = () => resolve([type, '/images/outcomes/assignment.svg'])
          }),
      )

      const results = await Promise.all(loadPromises)

      // Update cache with new icons
      setIconCache(prevCache => {
        const newCache = new Map(prevCache)
        results.forEach(([type, src]) => newCache.set(type, src))
        return newCache
      })
    }

    if (alignmentsWithScores.length > 0) {
      loadIcons()
    }
  }, [alignmentsWithScores, iconCache])

  if (alignmentsWithScores.length === 0) {
    return null
  }

  return (
    <Flex.Item width={hasChartView ? '66.67%' : '100%'}>
      <View
        as="div"
        //borderWidth="small"
        //borderRadius="large"
        padding="small"
      >
        <Flex direction="column" gap="x-small">
          {alignmentsWithScores.map((alignment, index) => (
            <View
              key={alignment.alignmentId}
              as="div"
              padding="x-small"
              //background={index % 2 === 0 ? 'secondary' : 'primary'}
              borderRadius="medium"
              data-testid={`alignment-item-${alignment.alignmentId}`}
            >
              <Flex gap="small" alignItems="start">
                {/* Timeline Circle */}
                <Flex.Item width="32px">
                  <div style={{position: 'relative', width: '32px'}}>
                    {/* Circle with checkmark or empty */}
                    <div
                      style={{
                        width: '24px',
                        height: '24px',
                        borderRadius: '50%',
                        border:
                          alignment.score !== null ? '1px solid #0B874B' : '1px solid #C7CDD1',
                        backgroundColor: 'white',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        position: 'relative',
                        zIndex: 1,
                      }}
                    >
                      {alignment.score !== null && <IconCheckMarkLine color="success" width={14} />}
                    </div>

                    {/* Connecting line to next item */}
                    {index < alignmentsWithScores.length - 1 && (
                      <div
                        style={{
                          position: 'absolute',
                          left: '13px',
                          top: '32px',
                          width: '1px',
                          height: '24px',
                          backgroundColor: '#C7CDD1',
                        }}
                      />
                    )}
                  </div>
                </Flex.Item>

                {/* Assignment Type Icon */}
                <Flex.Item width="1rem">
                  {iconCache.has(alignment.type) && (
                    <img
                      src={iconCache.get(alignment.type)}
                      alt={alignment.type}
                      style={{width: '1rem', height: '1rem'}}
                    />
                  )}
                </Flex.Item>

                {/* Title and Date */}
                <Flex.Item shouldGrow={true} shouldShrink={true}>
                  <Flex direction="column" gap="xx-small">
                    <Link href={alignment.htmlUrl} isWithinText={false}>
                      <Text weight="bold" size="small">
                        {alignment.title}
                      </Text>
                    </Link>
                    <Text size="x-small" color="secondary">
                      {alignment.submittedAt
                        ? new Date(alignment.submittedAt).toLocaleDateString(I18n.currentLocale(), {
                            year: 'numeric',
                            month: 'long',
                            day: 'numeric',
                          })
                        : I18n.t('Not submitted')}
                    </Text>
                  </Flex>
                </Flex.Item>

                {/* Mastery Detail */}
                <Flex.Item>
                  <MasteryDetail
                    masteryLevel={alignment.masteryLevel}
                    description={
                      typeof alignment.masteryLevel === 'number' && proficiencyRatings
                        ? getDescriptionForLevel(alignment.masteryLevel, proficiencyRatings)
                        : undefined
                    }
                  />
                </Flex.Item>
              </Flex>
            </View>
          ))}
        </Flex>
      </View>
    </Flex.Item>
  )
}

export default OutcomeAlignmentsList
