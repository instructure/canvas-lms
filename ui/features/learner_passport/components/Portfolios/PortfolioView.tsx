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

import React, {useCallback} from 'react'
import {useActionData, useLoaderData, useNavigate} from 'react-router-dom'
import {Breadcrumb} from '@instructure/ui-breadcrumb'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {
  IconCertifiedSolid,
  IconDownloadLine,
  IconEditLine,
  IconLinkLine,
  IconPrinterLine,
  IconReviewScreenLine,
  IconShareLine,
} from '@instructure/ui-icons'
import {Img} from '@instructure/ui-img'
import {List} from '@instructure/ui-list'
import {Link} from '@instructure/ui-link'
import {Tag} from '@instructure/ui-tag'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import type {
  AchievementData,
  PortfolioDetailData,
  SkillData,
  EducationData,
  ExperienceData,
} from '../types'
import AchievementCard from '../Achievements/AchievementCard'
import EducationCard from '../Education/EducationCard'
import {compareEducationDates} from '../utils'

function renderSkillTag(skill: SkillData) {
  return (
    <Tag
      key={skill.name.replace(/\s+/g, '-').toLowerCase()}
      text={
        <>
          {skill.verified ? <IconCertifiedSolid color="success" title="certified" /> : null}{' '}
          {skill.name}
        </>
      }
      margin="0 x-small 0 0"
    />
  )
}

function renderLink(link: string) {
  return (
    <List.Item key={link.replace(/\W+/, '-')}>
      <Link href={link} renderIcon={<IconLinkLine color="primary" size="x-small" />}>
        {link}
      </Link>
    </List.Item>
  )
}

function renderAchievement(achievement: AchievementData) {
  return (
    <AchievementCard
      isNew={achievement.isNew}
      title={achievement.title}
      issuer={achievement.issuer.name}
      imageUrl={achievement.imageUrl}
    />
  )
}

const dateFormatter = new Intl.DateTimeFormat(ENV.LOCALE, {
  month: 'numeric',
  year: 'numeric',
}).format

function formatDate(date: string) {
  return dateFormatter(new Date(date))
}

function renderExperience(experience: ExperienceData) {
  return (
    <View as="div" margin="0 0 small 0" padding="x-small" shadow="resting">
      <Text size="x-small" weight="light">
        {formatDate(experience.from_date)} - {formatDate(experience.to_date)}
      </Text>
      <Heading level="h4" margin="small 0 0 0" themeOverride={{h4FontSize: '1.375rem'}}>
        {experience.where}
      </Heading>
      <Text as="div">{experience.title}</Text>
      <View as="div" margin="medium 0 0 0">
        <Text as="div" size="small">
          <div dangerouslySetInnerHTML={{__html: experience.description}} />
        </Text>
      </View>
    </View>
  )
}

const PortfolioView = () => {
  const navigate = useNavigate()
  const create_portfolio = useActionData() as PortfolioDetailData
  const edit_portfolio = useLoaderData() as PortfolioDetailData
  const portfolio = create_portfolio || edit_portfolio

  const handleEditClick = useCallback(() => {
    navigate(`../edit/${portfolio.id}`)
  }, [navigate, portfolio.id])

  return (
    <View as="div" id="foo" maxWidth="986px" margin="0 auto">
      <Breadcrumb label="You are here:" size="small">
        <Breadcrumb.Link href={`/users/${ENV.current_user.id}/passport/portfolios/dashboard`}>
          Portfolios
        </Breadcrumb.Link>
        <Breadcrumb.Link>{portfolio.title}</Breadcrumb.Link>
      </Breadcrumb>
      <Flex as="div" margin="0 0 medium 0">
        <Flex.Item shouldGrow={true}>
          <Heading level="h1" themeOverride={{h1FontWeight: 700}}>
            {portfolio.title}
          </Heading>
        </Flex.Item>
        <Flex.Item>
          <Button margin="0 x-small 0 0" renderIcon={IconEditLine} onClick={handleEditClick}>
            Edit
          </Button>
          <Button margin="0 x-small 0 0" renderIcon={IconDownloadLine}>
            Download
          </Button>
          <Button margin="0 x-small 0 0" renderIcon={IconPrinterLine}>
            Print
          </Button>
          <Button margin="0 x-small 0 0" renderIcon={IconReviewScreenLine}>
            Preview
          </Button>
          <Button color="primary" margin="0" renderIcon={IconShareLine}>
            Share
          </Button>
        </Flex.Item>
      </Flex>
      <View as="div">
        <div style={{position: 'relative'}}>
          <div style={{height: '184px', background: '#C7CDD1', overflow: 'hidden', zIndex: -1}}>
            {portfolio.heroImageUrl && (
              <Img
                src={portfolio.heroImageUrl}
                alt="Cover image"
                constrain="cover"
                height="184px"
              />
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
            <Flex as="div" direction="column" gap="large">
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
              <View as="div">
                <Heading level="h3" themeOverride={{h3FontSize: '1rem'}}>
                  Links
                </Heading>
                <List isUnstyled={true} itemSpacing="small" margin="small 0 0 0">
                  {portfolio.links.map((link: string) => renderLink(link))}
                </List>
              </View>
              <View as="div" borderWidth="small 0 0 0" padding="large 0 0 0">
                <Heading level="h3" themeOverride={{h3FontSize: '1rem'}}>
                  Education
                </Heading>
                <List isUnstyled={true} itemSpacing="small" margin="small 0 0 0">
                  {portfolio.education
                    .sort(compareEducationDates)
                    .map((education: EducationData) => {
                      return (
                        <List.Item key={education.institution.replace(/\W+/, '-')}>
                          <View as="div" shadow="resting">
                            <EducationCard education={education} />
                          </View>
                        </List.Item>
                      )
                    })}
                </List>
              </View>
              <View as="div" borderWidth="small 0 0 0" padding="large 0 0 0">
                <Heading level="h3" themeOverride={{h3FontSize: '1rem'}} margin="large 0 small 0">
                  Experience
                </Heading>
                <View as="div" shadow="resting" padding="small">
                  <Flex direction="column" gap="small">
                    {portfolio.experience.map((experience: ExperienceData) => {
                      return (
                        <Flex.Item key={`${experience.where.replace(/\W+/, '-')}`}>
                          {renderExperience(experience)}
                        </Flex.Item>
                      )
                    })}
                  </Flex>
                </View>
              </View>
              <View as="div" borderWidth="small 0 0 0">
                <Heading level="h3" themeOverride={{h3FontSize: '1rem'}} margin="large 0 small 0">
                  Achievements
                </Heading>
                <Flex as="div" margin="small 0" gap="medium" wrap="wrap">
                  {portfolio.achievements.map((achievement: AchievementData) => {
                    return (
                      <Flex.Item key={achievement.id} shouldShrink={false}>
                        {renderAchievement(achievement)}
                      </Flex.Item>
                    )
                  })}
                </Flex>
              </View>
            </Flex>
          </div>
        </div>
      </View>
    </View>
  )
}

export default PortfolioView
