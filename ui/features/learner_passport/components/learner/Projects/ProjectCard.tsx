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
import {Flex} from '@instructure/ui-flex'
import {Img} from '@instructure/ui-img'
import {Tag} from '@instructure/ui-tag'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {renderSkillTag} from '../../shared/SkillTag'
import type {ProjectData} from '../../types'

const PROJECT_CARD_WIDTH = '400px'
const PROJECT_CARD_HEIGHT = '280px'
const PROJECT_CARD_IMAGE_HEIGHT = `${200 - 96}px`

export type ProjectCardProps = {
  project: ProjectData
}

const ProjectCard = ({project}: ProjectCardProps) => {
  return (
    <View id={`project-${project.id}`} as="div" width={PROJECT_CARD_WIDTH} height="auto">
      <View as="div" height={PROJECT_CARD_IMAGE_HEIGHT} overflowY="hidden">
        {project.heroImageUrl ? (
          <Img
            src={project.heroImageUrl}
            alt="Cover image"
            constrain="cover"
            height={PROJECT_CARD_IMAGE_HEIGHT}
          />
        ) : (
          <div
            style={{
              width: '100%',
              height: PROJECT_CARD_IMAGE_HEIGHT,
              background:
                'repeating-linear-gradient(45deg, #cecece, #cecece 10px, #aeaeae 10px, #aeaeae 20px)',
            }}
          />
        )}
      </View>
      <Flex as="div" direction="column" gap="small" padding="small">
        <Flex.Item shouldGrow={true}>
          <Text weight="bold" size="large">
            {project.title}
          </Text>
        </Flex.Item>
        {project.skills?.length > 0 ? (
          <Flex.Item>
            <Flex>
              {project.skills.length > 0 ? renderSkillTag(project.skills[0]) : null}
              {project.skills.length > 1 ? renderSkillTag(project.skills[1]) : null}
              {project.skills.length > 2 ? (
                <Tag
                  key="more-skills"
                  text={`+${project.skills.length - 2} more`}
                  margin="0 x-small x-small 0"
                />
              ) : null}
            </Flex>
          </Flex.Item>
        ) : null}
        <Flex.Item>
          <Flex margin="medium 0 0 0" gap="small">
            <Flex.Item>
              <div
                style={{
                  display: 'inline-block',
                  borderRadius: '50%',
                  backgroundColor: '#F5F5F5',
                  marginInlineEnd: '.25rem',
                  padding: '.25rem',
                  width: '1rem',
                  height: '1rem',
                  lineHeight: '1rem',
                  textAlign: 'center',
                  fontSize: '.75rem',
                }}
              >
                {project.attachments.length}
              </div>
              <Text size="small">Attachments</Text>
            </Flex.Item>
            <View borderWidth="0 0 0 small" height="1.5rem" />
            <Flex.Item>
              <div
                style={{
                  display: 'inline-block',
                  borderRadius: '50%',
                  backgroundColor: '#F5F5F5',
                  marginInlineEnd: '.25rem',
                  padding: '.25rem',
                  width: '1rem',
                  height: '1rem',
                  lineHeight: '1rem',
                  textAlign: 'center',
                  fontSize: '.75rem',
                }}
              >
                {project.achievements.length}
              </div>
              <Text size="small">Achievements</Text>
            </Flex.Item>
          </Flex>
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default ProjectCard
export {PROJECT_CARD_HEIGHT, PROJECT_CARD_WIDTH, PROJECT_CARD_IMAGE_HEIGHT}
