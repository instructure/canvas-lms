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
  IconDownloadLine,
  IconEditLine,
  IconPrinterLine,
  IconReviewScreenLine,
  IconShareLine,
} from '@instructure/ui-icons'
import {Img} from '@instructure/ui-img'
import {List} from '@instructure/ui-list'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import AttachmentsTable from './AttachmentsTable'
import type {AchievementData, ProjectDetailData, SkillData} from '../types'
import {renderSkillTag} from '../shared/SkillTag'
import {renderAchievement, renderLink} from '../shared/utils'

const ProjectView = () => {
  const navigate = useNavigate()
  const create_project = useActionData() as ProjectDetailData
  const edit_project = useLoaderData() as ProjectDetailData
  const project = create_project || edit_project

  const handleEditClick = useCallback(() => {
    navigate(`../edit/${project.id}`)
  }, [navigate, project.id])

  return (
    <View as="div" id="foo" maxWidth="986px" margin="0 auto">
      <Breadcrumb label="You are here:" size="small">
        <Breadcrumb.Link href={`/users/${ENV.current_user.id}/passport/projects/dashboard`}>
          Projects
        </Breadcrumb.Link>
        <Breadcrumb.Link>{project.title}</Breadcrumb.Link>
      </Breadcrumb>
      <Flex as="div" margin="0 0 medium 0" justifyItems="end">
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
      <View as="div" margin="0 0 large 0">
        <div style={{height: '184px', background: '#C7CDD1', overflow: 'hidden', zIndex: -1}}>
          {project.heroImageUrl && (
            <Img src={project.heroImageUrl} alt="Cover image" constrain="cover" height="184px" />
          )}
        </div>
      </View>
      <Heading level="h1" themeOverride={{h1FontWeight: 700}} margin="0 0 small 0">
        {project.title}
      </Heading>

      <View as="div" margin="0 0 large 0">
        <Heading level="h3" themeOverride={{h3FontSize: '1rem'}}>
          By {ENV.current_user.display_name}
        </Heading>
      </View>

      <View as="div" margin="0 0 large 0">
        <Heading level="h3" themeOverride={{h3FontSize: '1rem'}}>
          Skills and tools
        </Heading>
        <View as="div" margin="small 0">
          {project.skills.map((skill: SkillData) => renderSkillTag(skill))}
        </View>
      </View>

      <View as="div" margin="0 0 large 0">
        <Heading level="h3" themeOverride={{h3FontSize: '1rem'}} margin="0 0 x-small 0">
          Description
        </Heading>
        <Text as="div" size="small" wrap="break-word">
          <div dangerouslySetInnerHTML={{__html: project.description}} />
        </Text>
      </View>
      {project.attachments.length > 0 && (
        <View as="div" margin="0 0 large 0">
          <Heading level="h3" themeOverride={{h3FontSize: '1rem'}}>
            Attachments
          </Heading>
          <AttachmentsTable attachments={project.attachments} />
        </View>
      )}
      {project.links.length > 0 && (
        <View as="div" margin="0 0 large 0">
          <Heading level="h3" themeOverride={{h3FontSize: '1rem'}}>
            Links
          </Heading>
          <List isUnstyled={true} itemSpacing="small" margin="small 0 0 0">
            {project.links.map((link: string) => renderLink(link))}
          </List>
        </View>
      )}
      {project.achievements.length > 0 && (
        <View as="div" margin="0 0 large 0">
          <Heading level="h3" themeOverride={{h3FontSize: '1rem'}} margin="large 0 small 0">
            Achievements
          </Heading>
          <Flex as="div" margin="small 0" gap="medium" wrap="wrap">
            {project.achievements.map((achievement: AchievementData) => {
              return (
                <Flex.Item key={achievement.id} shouldShrink={false}>
                  {renderAchievement(achievement)}
                </Flex.Item>
              )
            })}
          </Flex>
        </View>
      )}
    </View>
  )
}

export default ProjectView
