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
  ProjectDetailData,
  SkillData,
} from '../../types'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Img} from '@instructure/ui-img'
import {List} from '@instructure/ui-list'
import {SVGIcon} from '@instructure/ui-svg-images'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {compareFromToDates, renderAchievement, renderLink, renderProject} from '../../shared/utils'
import {renderSkillTag} from '../../shared/SkillTag'
import EducationCard from '../Education/EducationCard'
import ExperienceCard from '../Experience/ExperienceCard'
import AchievementTray from '../Achievements/AchievementTray'
import ProjectTray from '../Projects/ProjectTray'

const pinSVG = `<svg width="18" height="18" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M12.2812 10.1565C11.2114 11.2174 9.903 12.6866 9.16837 14.5328C8.44725 12.6664 7.15125 11.2061 6.09375 10.1554C4.7685 8.8425 4.125 7.53525 4.125 6.15713C4.125 3.38288 6.38288 1.125 9.21675 1.125C11.9921 1.125 14.25 3.38288 14.25 6.15713C14.25 7.53525 13.6065 8.8425 12.2812 10.1565ZM9.15825 0C5.763 0 3 2.76187 3 6.15712C3 7.85025 3.75263 9.41963 5.30062 10.9541C7.54837 13.1839 8.59575 15.2437 8.59575 17.4375V18H9.72075V17.4375C9.72075 15.2539 10.7557 13.2547 13.0744 10.9552C14.6224 9.41962 15.375 7.85025 15.375 6.15712C15.375 2.76187 12.612 0 9.15825 0Z" fill="#2D3B45"/>
</svg>`
const phoneSVG = `<svg width="10" height="18" viewBox="0 0 10 18" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M9.53674e-07 -4.80825e-07L2.38397e-07 18L10 18L10 6.33498e-07L9.53674e-07 -4.80825e-07ZM0.888047 1.05859L9.06072 1.05859L9.06072 16.9409L8.74681 16.9409L0.888047 16.9409L0.888047 1.05859Z" fill="#2D3B45"/>
</svg>`
const emailSVG = `<svg width="18" height="18" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M0 15.7647H18V2H0V15.7647ZM1.05882 3.41247V3.05883H16.9412V3.41247L9 10.2991L1.05882 3.41247ZM16.9412 4.81435V13.7254L13.6493 9.61082L12.8213 10.2715L16.3684 14.7059H1.63164L5.1787 10.2715L4.3507 9.61082L1.05882 13.7254V4.81435L9 11.7009L16.9412 4.81435Z" fill="#394B58"/>
</svg>`

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
  const [activeAchievement, setActiveAchievement] = useState<AchievementData | undefined>(undefined)
  const [activeProject, setActiveProject] = useState<ProjectDetailData | undefined>(undefined)

  const handleAchievementCardClick = useCallback(
    (achievementId: string) => {
      const card = portfolio.achievements.find(a => a.id === achievementId)
      setActiveAchievement(card)
      setActiveProject(undefined)
    },
    [portfolio.achievements, setActiveAchievement, setActiveProject]
  )

  const handleProjectCardClick = useCallback(
    (projectId: string) => {
      const card = portfolio.projects.find(a => a.id === projectId)
      setActiveProject(card)
      setActiveAchievement(undefined)
    },
    [portfolio.projects, setActiveAchievement, setActiveProject]
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
                  backgroundRepeat: 'no-repeat',
                  backgroundPosition: 'center center',
                  backgroundColor: '#f5f5f5',
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
          <Flex as="div" direction="column" gap="large" padding="0 medium" margin="large 0 0 0">
            <View as="div" background="secondary" padding="small">
              <Flex as="div" direction="row" justifyItems="center" gap="xx-large">
                <Flex.Item align="start">
                  <div style={{display: 'inline-block', marginRight: '0.25rem'}}>
                    <SVGIcon src={pinSVG} inline={true} width="1rem" height="1rem" />
                  </div>
                  <Text>
                    {portfolio.city}, {portfolio.state}
                  </Text>
                </Flex.Item>
                <Flex.Item align="start">
                  <div style={{display: 'inline-block', marginRight: '0.25rem'}}>
                    <SVGIcon src={phoneSVG} inline={true} width="1rem" height="1rem" />
                  </div>
                  <Text>{portfolio.phone}</Text>
                </Flex.Item>
                <Flex.Item align="start">
                  <div style={{display: 'inline-block', marginRight: '0.25rem'}}>
                    <SVGIcon src={emailSVG} inline={true} width="1rem" height="1rem" />
                  </div>
                  <Text>{portfolio.email}</Text>
                </Flex.Item>
              </Flex>
            </View>
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
            {portfolio.projects.length > 0 && (
              <View as="div" borderWidth="small 0 0 0">
                <Heading level="h3" themeOverride={{h3FontSize: '1rem'}} margin="large 0 small 0">
                  Projects
                </Heading>
                <Flex as="div" margin="small 0" gap="medium" wrap="wrap">
                  {portfolio.projects.map((project: ProjectDetailData) => {
                    return (
                      <Flex.Item key={project.id} shouldShrink={false}>
                        {renderProject(project, handleProjectCardClick)}
                      </Flex.Item>
                    )
                  })}
                </Flex>
              </View>
            )}
            <View as="div" borderWidth="small 0 0 0">
              <Heading level="h3" themeOverride={{h3FontSize: '1rem'}} margin="large 0 small 0">
                Achievements
              </Heading>
              <Flex as="div" margin="small 0" gap="medium" wrap="wrap">
                {portfolio.achievements.map((achievement: AchievementData) => {
                  return (
                    <Flex.Item key={achievement.id} shouldShrink={false}>
                      {renderAchievement(achievement, handleAchievementCardClick)}
                    </Flex.Item>
                  )
                })}
              </Flex>
            </View>
          </Flex>
        </div>
      </div>
      <AchievementTray
        open={!!activeAchievement}
        onClose={() => setActiveAchievement(undefined)}
        activeCard={activeAchievement}
      />
      <ProjectTray
        open={!!activeProject}
        project={activeProject}
        onClose={() => setActiveProject(undefined)}
      />
    </View>
  )
}

export default PortfolioView
