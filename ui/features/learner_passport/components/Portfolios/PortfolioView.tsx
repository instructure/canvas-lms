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

import React, {useCallback, useState} from 'react'
import type {
  AchievementData,
  EducationData,
  ExperienceData,
  PortfolioDetailData,
  SkillData,
} from '../types'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Img} from '@instructure/ui-img'
import {List} from '@instructure/ui-list'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {compareFromToDates, renderAchievement, renderLink} from '../shared/utils'
import {renderSkillTag} from '../shared/SkillTag'
import EducationCard from '../Education/EducationCard'
import ExperienceCard from '../Experience/ExperienceCard'
import AchievementTray from '../Achievements/AchievementTray'

function renderEducation(education: EducationData) {
  return (
    <View as="div" shadow="resting">
      <EducationCard education={education} />
    </View>
  )
}

function renderExperience(experience: ExperienceData) {
  return (
    <View as="div" shadow="resting">
      <ExperienceCard experience={experience} />
    </View>
  )
}

type PortfolioViewProps = {
  portfolio: PortfolioDetailData
}

const PortfolioView = ({portfolio}: PortfolioViewProps) => {
  const [showingAchievementDetails, setShowingAchievementDetails] = useState(false)
  const [activeCard, setActiveCard] = useState<AchievementData | undefined>(undefined)

  const handleDismissAchievementDetails = useCallback(() => {
    setShowingAchievementDetails(false)
    setActiveCard(undefined)
  }, [])

  const showAchievementDetails = useCallback(
    (achievementId: string) => {
      const card = portfolio.achievements.find(a => a.id === achievementId)
      setActiveCard(card)
      setShowingAchievementDetails(card !== undefined)
    },
    [portfolio.achievements]
  )

  const handleAchievementCardClick = useCallback(
    (e: React.MouseEvent) => {
      // @ts-expect-error
      showAchievementDetails(e.currentTarget.getAttribute('data-cardid'))
    },
    [showAchievementDetails]
  )

  const handleAchievementCardKey = useCallback(
    (e: React.KeyboardEvent) => {
      if (e.key === 'Enter') {
        // @ts-expect-error
        showAchievementDetails(e.currentTarget.getAttribute('data-cardid'))
      }
    },
    [showAchievementDetails]
  )

  return (
    <View as="div">
      <div style={{position: 'relative'}}>
        <div style={{height: '184px', background: '#C7CDD1', overflow: 'hidden', zIndex: -1}}>
          {portfolio.heroImageUrl && (
            <Img src={portfolio.heroImageUrl} alt="Cover image" constrain="cover" height="184px" />
          )}
        </div>
        <div style={{position: 'relative', top: '-5rem'}}>
          <Flex direction="column">
            <Flex.Item align="center">
              <div
                style={{
                  boxSizing: 'border-box',
                  margin: '0 auto 0 auto',
                  borderRadius: '50%',
                  width: '10rem',
                  height: '10rem',
                  overflow: 'hidden',
                  border: '6px solid white',
                  boxShadow:
                    '0px 1px 3px 0px rgba(0, 0, 0, 0.10), 0px 1px 2px 0px rgba(0, 0, 0, 0.20)',
                  backgroundImage: ENV.current_user.avatar_image_url
                    ? `url(${ENV.current_user.avatar_image_url})`
                    : 'none',
                }}
              />
            </Flex.Item>
            <Flex.Item align="center" margin="small 0 0 0" overflowY="visible">
              <Heading level="h2">{ENV.current_user.display_name}</Heading>
            </Flex.Item>
            <Flex.Item align="center">
              <Text size="x-small">{portfolio.blurb}</Text>
            </Flex.Item>
          </Flex>
          <Flex as="div" direction="column" gap="large" padding="0 medium">
            <View as="div">
              <Heading level="h3" themeOverride={{h3FontSize: '1rem'}}>
                About Me
              </Heading>
              <p>{portfolio.about || ''}</p>
            </View>
            <View as="div">
              <Heading level="h3" themeOverride={{h3FontSize: '1rem'}}>
                Skills
              </Heading>
              <View as="div" margin="small 0">
                {portfolio.skills.map((skill: SkillData) => renderSkillTag(skill))}
              </View>
            </View>
            {portfolio.links.length > 0 && (
              <View as="div">
                <Heading level="h3" themeOverride={{h3FontSize: '1rem'}}>
                  Links
                </Heading>
                <List isUnstyled={true} itemSpacing="small" margin="small 0 0 0">
                  {portfolio.links.map((link: string) => renderLink(link))}
                </List>
              </View>
            )}
            <View as="div" borderWidth="small 0 0 0">
              <Heading level="h3" themeOverride={{h3FontSize: '1rem'}} margin="large 0 small 0">
                Education
              </Heading>
              <List isUnstyled={true} itemSpacing="small" margin="small 0 0 0">
                {portfolio.education.sort(compareFromToDates).map((education: EducationData) => {
                  return (
                    <List.Item key={education.institution.replace(/\W+/, '-')}>
                      {renderEducation(education)}
                    </List.Item>
                  )
                })}
              </List>
            </View>
            <View as="div" borderWidth="small 0 0 0">
              <Heading level="h3" themeOverride={{h3FontSize: '1rem'}} margin="large 0 small 0">
                Experience
              </Heading>
              <List isUnstyled={true} itemSpacing="small" margin="small 0 0 0">
                {portfolio.experience.map((experience: ExperienceData) => {
                  return (
                    <List.Item key={`${experience.where.replace(/\W+/, '-')}`}>
                      {renderExperience(experience)}
                    </List.Item>
                  )
                })}
              </List>
            </View>
            <View as="div" borderWidth="small 0 0 0">
              <Heading level="h3" themeOverride={{h3FontSize: '1rem'}} margin="large 0 small 0">
                Achievements
              </Heading>
              <Flex as="div" margin="small 0" gap="medium" wrap="wrap">
                {portfolio.achievements.map((achievement: AchievementData) => {
                  return (
                    <Flex.Item key={achievement.id} shouldShrink={false}>
                      {renderAchievement(
                        achievement,
                        handleAchievementCardClick,
                        handleAchievementCardKey
                      )}
                    </Flex.Item>
                  )
                })}
              </Flex>
            </View>
          </Flex>
        </div>
      </div>
      {activeCard && (
        <AchievementTray
          open={showingAchievementDetails}
          onDismiss={handleDismissAchievementDetails}
          activeCard={activeCard}
        />
      )}
    </View>
  )
}

export default PortfolioView
