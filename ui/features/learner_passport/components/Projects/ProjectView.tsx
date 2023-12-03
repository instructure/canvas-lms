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

import React from 'react'
import {AchievementData, ProjectDetailData, SkillData} from '../types'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {List} from '@instructure/ui-list'
import {View} from '@instructure/ui-view'
import {Img} from '@instructure/ui-img'
import AttachmentsTable from './AttachmentsTable'
import {renderAchievement, renderLink} from '../shared/utils'
import {renderSkillTag} from '../shared/SkillTag'

type ProjectViewProps = {
  project: ProjectDetailData
}

const ProjectView = ({project}: ProjectViewProps) => {
  return (
    <>
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
    </>
  )
}

export default ProjectView
