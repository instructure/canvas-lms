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
import {useActionData, useLoaderData, useSubmit} from 'react-router-dom'
import {Breadcrumb} from '@instructure/ui-breadcrumb'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconDragHandleLine, IconReviewScreenLine, IconSaveLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import HeadingEditor from '../../../shared/HeadingEditor'
import {showUnimplemented} from '../../../shared/utils'
import PersonalInfo from './personal_info/PersonalInfo'
import AchievementsEditToggle from './achievements/AchievementsEdit'
import EducationEdit from './education/EducationEdit'
import ExperienceEdit from './experience/ExperienceEdit'
import ProjectsEditToggle from './projects/ProjectsEdit'
import PortfolioPreviewModal from '../PortfolioPreviewModal'

import type {
  EducationData,
  ExperienceData,
  PortfolioDetailData,
  PortfolioEditData,
  SkillData,
} from '../../../types'

const PortfolioEdit = () => {
  const submit = useSubmit()
  const create_portfolio = useActionData() as PortfolioEditData
  const edit_portfolio = useLoaderData() as PortfolioEditData
  const portfolio_data = create_portfolio || edit_portfolio
  const portfolio = portfolio_data.portfolio
  const allAchievements = portfolio_data.achievements
  const allProjects = portfolio_data.projects
  const [achievementIds, setAchievementIds] = useState<string[]>(() => {
    return portfolio.achievements.map(achievement => achievement.id)
  })
  const [projectIds, setProjectIds] = useState<string[]>(() => {
    return portfolio.projects.map(project => project.id)
  })
  const [title, setTitle] = useState(portfolio.title)
  const [education, setEducation] = useState(portfolio.education)
  const [experience, setExperience] = useState(portfolio.experience)
  const [showPreview, setShowPreview] = useState(false)
  const [previewPortfolio, setPreviewPortfolio] = useState(portfolio)

  const handlePreviewClick = useCallback(() => {
    setPreviewPortfolio({
      ...previewPortfolio,
      title,
      education,
      experience,
      achievements: allAchievements.filter(achievement => achievementIds.includes(achievement.id)),
    })
    setShowPreview(true)
  }, [previewPortfolio, title, education, experience, allAchievements, achievementIds])

  const handleClosePreview = useCallback(() => {
    setShowPreview(false)
  }, [])

  const handleChangePersonalInfo = useCallback(
    (newPortfolioData: Partial<PortfolioDetailData>) => {
      setPreviewPortfolio({...previewPortfolio, ...newPortfolioData})
    },
    [previewPortfolio]
  )

  const handleTitleChange = useCallback((newTitle: string) => {
    setTitle(newTitle)
  }, [])

  const handleSaveClick = useCallback(() => {
    ;(document.getElementById('edit_portfolio_form') as HTMLFormElement)?.requestSubmit()
  }, [])

  const handleSubmit = useCallback(
    (e: React.FormEvent<HTMLFormElement>) => {
      e.preventDefault()
      const form = document.getElementById('edit_portfolio_form') as HTMLFormElement
      const formData = new FormData(form)

      const skills = JSON.parse(formData.get('skills') as string)
      formData.delete('skills')
      skills.forEach((skill: SkillData) => {
        formData.append('skills[]', JSON.stringify(skill))
      })

      submit(formData, {method: 'POST'})
    },
    [submit]
  )

  const handleNewAchievements = useCallback((newAchievementIds: string[]) => {
    setAchievementIds(newAchievementIds)
  }, [])

  const handleNewEducation = useCallback((newEducation: EducationData[]) => {
    setEducation(newEducation)
  }, [])

  const handleNewExperience = useCallback((newExperience: ExperienceData[]) => {
    setExperience(newExperience)
  }, [])

  const handleNewProjects = useCallback((newProjectIds: string[]) => {
    setProjectIds(newProjectIds)
  }, [])

  return (
    <View as="div">
      <View as="div" maxWidth="986px" margin="0 auto">
        <form id="edit_portfolio_form" method="POST" onSubmit={handleSubmit}>
          <Flex as="div" direction="column" gap="medium" margin="0 0 xx-small 0">
            <input type="hidden" name="id" value={portfolio.id} />
            <Breadcrumb label="You are here:" size="small">
              <Breadcrumb.Link
                href={`/users/${ENV.current_user.id}/passport/learner/portfolios/dashboard`}
              >
                Portfolios
              </Breadcrumb.Link>
              <Breadcrumb.Link
                href={`/users/${ENV.current_user.id}/passport/learner/portfolios/view/${portfolio.id}`}
              >
                {title}
              </Breadcrumb.Link>
              <Breadcrumb.Link>edit</Breadcrumb.Link>
            </Breadcrumb>
            <Flex as="div" margin="0 0 medium 0" gap="small">
              <Flex.Item shouldGrow={true}>
                <HeadingEditor value={title} onChange={handleTitleChange} />
                <input type="hidden" name="title" value={title} />
              </Flex.Item>
              <Flex.Item>
                <Button
                  margin="0 x-small 0 0"
                  renderIcon={IconDragHandleLine}
                  onClick={showUnimplemented}
                >
                  Reorder
                </Button>
                <Button
                  margin="0 x-small 0 0"
                  renderIcon={IconReviewScreenLine}
                  onClick={handlePreviewClick}
                >
                  Preview
                </Button>
                <Button margin="0 x-small 0 0" renderIcon={IconSaveLine} onClick={handleSaveClick}>
                  Save
                </Button>
              </Flex.Item>
            </Flex>
            <View margin="0 medium" borderWidth="small">
              <PersonalInfo portfolio={portfolio} onChange={handleChangePersonalInfo} />
            </View>
            <View margin="0 medium" borderWidth="small">
              <input type="hidden" name="education" value={JSON.stringify(education)} />
              <EducationEdit education={education} onChange={handleNewEducation} />
            </View>
            <View margin="0 medium" borderWidth="small">
              <input type="hidden" name="experience" value={JSON.stringify(experience)} />
              <ExperienceEdit experience={experience} onChange={handleNewExperience} />
            </View>
            <View margin="0 medium" borderWidth="small">
              <input type="hidden" name="projects" value={projectIds.join(',')} />
              <ProjectsEditToggle
                allProjects={allProjects}
                selectedProjectIds={projectIds}
                onChange={handleNewProjects}
              />
            </View>
            <View margin="0 medium" borderWidth="small">
              <input type="hidden" name="achievements" value={achievementIds.join(',')} />
              <AchievementsEditToggle
                allAchievements={allAchievements}
                selectedAchievementIds={achievementIds}
                onChange={handleNewAchievements}
              />
            </View>
          </Flex>
        </form>
      </View>
      <div
        id="footer"
        style={{
          position: 'sticky',
          bottom: '0',
          margin: '0 -3rem',
        }}
      >
        <View as="div" background="primary" borderWidth="small 0 0 0">
          <Flex justifyItems="end" padding="small" gap="small">
            <Button onClick={showUnimplemented}>Reorder</Button>
            <Button onClick={handlePreviewClick}>Preview</Button>
            <Button color="primary" onClick={handleSaveClick}>
              Save
            </Button>
          </Flex>
        </View>
      </div>
      <PortfolioPreviewModal
        portfolio={previewPortfolio}
        open={showPreview}
        onClose={handleClosePreview}
      />
    </View>
  )
}

export default PortfolioEdit
