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
  IconLinkLine,
  IconPrinterLine,
  IconReviewScreenLine,
  IconShareLine,
  IconMsWordLine,
  IconPdfLine,
  IconImageLine,
} from '@instructure/ui-icons'
import {SVGIcon} from '@instructure/ui-svg-images'
import {Img} from '@instructure/ui-img'
import {List} from '@instructure/ui-list'
import {Link} from '@instructure/ui-link'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import type {ViewProps} from '@instructure/ui-view'
import type {AchievementData, AttachmentData, ProjectDetailData, SkillData} from '../types'
import AchievementCard from '../Achievements/AchievementCard'
import {renderSkillTag} from '../shared/SkillTag'
import {isUrlToLocalCanvasFile} from '../shared/utils'

function renderFileTypeIcon(contentType: string) {
  if (contentType === 'application/pdf') return <IconPdfLine />
  if (contentType === 'application/msword') return <IconMsWordLine />
  if (contentType.startsWith('image/')) return <IconImageLine />
  return (
    <SVGIcon src='<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="1rem" height="1rem"> </svg>' />
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
    <View as="div" shadow="resting">
      <AchievementCard
        isNew={achievement.isNew}
        title={achievement.title}
        issuer={achievement.issuer.name}
        imageUrl={achievement.imageUrl}
      />
    </View>
  )
}

const ProjectView = () => {
  const navigate = useNavigate()
  const create_project = useActionData() as ProjectDetailData
  const edit_project = useLoaderData() as ProjectDetailData
  const project = create_project || edit_project

  const handleEditClick = useCallback(() => {
    navigate(`../edit/${project.id}`)
  }, [navigate, project.id])

  const handleDownloadAttachment = useCallback(
    (event: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps>) => {
      const attachmentId = (event.target as HTMLButtonElement).getAttribute('data-attachmentId')
      if (!attachmentId) return
      const thisAttachment = project.attachments.find(attachment => attachment.id === attachmentId)
      if (!thisAttachment) return

      let href = thisAttachment.url
      if (isUrlToLocalCanvasFile(thisAttachment.url)) {
        const url = new URL(thisAttachment.url)
        url.searchParams.set('download', '1')
        href = url.href
      }

      const link = document.createElement('a')
      link.setAttribute('dowload', thisAttachment.filename)
      link.href = href
      link.click()
    },
    [project.attachments]
  )

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
          <Table caption="attachments" layout="auto">
            <Table.Head>
              <Table.Row>
                <Table.ColHeader id="fliename">File name</Table.ColHeader>
                <Table.ColHeader id="size" width="10rem">
                  Size
                </Table.ColHeader>
                <Table.ColHeader id="action" width="10rem">
                  Action
                </Table.ColHeader>
              </Table.Row>
            </Table.Head>
            <Table.Body>
              {project.attachments.map((attachment: AttachmentData) => {
                return (
                  <Table.Row key={attachment.id}>
                    <Table.Cell>
                      <Flex gap="small">
                        <Flex.Item shouldGrow={false}>
                          {renderFileTypeIcon(attachment.contentType)}
                        </Flex.Item>
                        <Flex.Item shouldGrow={true}>
                          <a href={attachment.url} target={attachment.filename}>
                            {attachment.filename}
                          </a>
                        </Flex.Item>
                      </Flex>
                    </Table.Cell>
                    <Table.Cell>{attachment.size}</Table.Cell>
                    <Table.Cell>
                      <Button
                        renderIcon={IconDownloadLine}
                        data-attachmentId={attachment.id}
                        onClick={handleDownloadAttachment}
                      >
                        Download
                      </Button>
                    </Table.Cell>
                  </Table.Row>
                )
              })}
            </Table.Body>
          </Table>
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
