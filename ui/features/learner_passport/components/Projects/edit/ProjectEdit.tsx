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
import {useActionData, useLoaderData, useNavigate, useSubmit} from 'react-router-dom'
import {Breadcrumb} from '@instructure/ui-breadcrumb'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {FormField} from '@instructure/ui-form-field'
import {Heading} from '@instructure/ui-heading'
import {IconAddLine, IconEditLine, IconReviewScreenLine, IconSaveLine} from '@instructure/ui-icons'
import {Img} from '@instructure/ui-img'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import type {ViewProps} from '@instructure/ui-view'
import AttachmentsTable from '../AttachmentsTable'
import {AchievementsEdit} from '../../Portfolios/edit/achievements/AchievementsEdit'
import type {AttachmentData, ProjectEditData, SkillData} from '../../types'
import {renderEditLink, stringToId} from '../../shared/utils'
import CoverImageModal from '../../shared/CoverImageModal'
import SkillSelect from '../../shared/SkillSelect'
import RichTextEdit from '../../shared/RichTextEdit'
import AddFilesModal from './AddFilesModal'

const ProjectEdit = () => {
  const navigate = useNavigate()
  const submit = useSubmit()
  const create_project = useActionData() as ProjectEditData
  const edit_project = useLoaderData() as ProjectEditData
  const project_data = create_project || edit_project
  const project = project_data.project
  const allAchievements = project_data.achievements
  const [achievementIds, setAchievementIds] = useState<string[]>(() => {
    return project.achievements.map(achievement => achievement.id)
  })
  const [heroImageUrl, setHeroImageUrl] = useState(project.heroImageUrl)
  const [attachments, setAttachments] = useState<AttachmentData[]>(project.attachments)
  const [links, setLinks] = useState(project.links)
  const [skills, setSkills] = useState(project.skills)
  const [description, setDescription] = useState(project.description)
  const [editCoverImageModalOpen, setEditCoverImageModalOpen] = useState(false)
  const [addFilesModalOpen, setAddFilesModalOpen] = useState(false)

  const handlePreviewClick = useCallback(() => {
    navigate(`../view/${project.id}`)
  }, [navigate, project.id])

  const handleSaveClick = useCallback(() => {
    ;(document.getElementById('edit_project_form') as HTMLFormElement)?.requestSubmit()
  }, [])

  const handleSubmit = useCallback(
    (e: React.FormEvent<HTMLFormElement>) => {
      e.preventDefault()

      const formData = new FormData(e.currentTarget)
      const data = {
        ...Object.fromEntries(formData),
        achievements: achievementIds,
      }

      submit(data)
    },
    [achievementIds, submit]
  )
  //
  // const handleAchievementIdsChange = useCallback(
  //   (achievementIds: string[]) => {
  //     setAchievementIds(achievementIds)
  //   },
  //   [setAchievementIds]
  // )

  const handleEditCoverImageClick = useCallback(() => {
    setEditCoverImageModalOpen(true)
  }, [])

  const handleCloseEditCoverImageModal = useCallback(() => {
    setEditCoverImageModalOpen(false)
  }, [])

  const handleSaveHeroImageUrl = useCallback((imageUrl: string | null) => {
    setHeroImageUrl(imageUrl)
    setEditCoverImageModalOpen(false)
  }, [])

  const handleSelectSkills = useCallback((newSkills: SkillData[]) => {
    setSkills(newSkills)
  }, [])

  const handleDescriptionChange = useCallback((content: string) => {
    setDescription(content)
  }, [])

  const handleAddLink = useCallback(() => {
    setLinks([...links, ''])
  }, [links])

  const handleDeleteLink = useCallback(
    (event: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps>) => {
      const link_id = (event.target as HTMLInputElement).getAttribute('data-linkid') as string
      const link = (document.getElementById(link_id) as HTMLInputElement).value
      setLinks(links.filter(l => l !== link))
    },
    [links]
  )

  const handleEditLink = useCallback((event: React.FocusEvent<HTMLInputElement>) => {
    event.preventDefault()
    setLinks(
      Array.from(document.getElementsByName('links[]')).map((link: HTMLElement) =>
        (link as HTMLInputElement).value.trim()
      )
    )
  }, [])

  const handlePickFiles = useCallback(() => {
    setAddFilesModalOpen(true)
  }, [])

  const handleCloseFilesModal = useCallback(() => {
    setAddFilesModalOpen(false)
  }, [])

  const handleAddFiles = useCallback(
    (newAttachments: AttachmentData[]) => {
      setAttachments([...attachments, ...newAttachments])
      setAddFilesModalOpen(false)
    },
    [attachments]
  )

  return (
    <View as="div">
      <View as="div" id="foo" maxWidth="986px" margin="0 auto">
        <form id="edit_project_form" method="POST" onSubmit={handleSubmit}>
          <Breadcrumb label="You are here:" size="small">
            <Breadcrumb.Link href={`/users/${ENV.current_user.id}/passport/projects/dashboard`}>
              Projects
            </Breadcrumb.Link>
            <Breadcrumb.Link
              href={`/users/${ENV.current_user.id}/passport/projects/view/${project.id}`}
            >
              {project.title}
            </Breadcrumb.Link>
            <Breadcrumb.Link>Edit</Breadcrumb.Link>
          </Breadcrumb>
          <Flex as="div" margin="0 0 medium 0" justifyItems="space-between">
            <Flex.Item shouldShrink={true}>
              <Heading level="h1" themeOverride={{h1FontSize: '1.5rem'}}>
                {project.title}
              </Heading>
            </Flex.Item>
            <Flex.Item>
              <Button margin="0 x-small 0 0" renderIcon={IconReviewScreenLine}>
                Preview
              </Button>
              <Button color="primary" margin="0" renderIcon={IconSaveLine}>
                Share
              </Button>
            </Flex.Item>
          </Flex>
          <View as="div">
            <View as="div" margin="medium 0">
              <div
                style={{
                  position: 'relative',
                  height: '184px',
                  background: '#C7CDD1',
                  overflow: 'hidden',
                }}
              >
                {heroImageUrl ? (
                  <Img src={heroImageUrl} alt="Cover image" constrain="cover" />
                ) : null}
                <div style={{position: 'absolute', right: '12px', bottom: '12px'}}>
                  <Button renderIcon={IconEditLine} onClick={handleEditCoverImageClick}>
                    Edit cover image
                  </Button>
                </div>
                <input type="hidden" name="heroImageUrl" value={heroImageUrl || ''} />
              </div>
            </View>

            <View as="div" margin="0 0 medium 0">
              <input type="hidden" name="skills" value={JSON.stringify(skills)} />
              <SkillSelect
                label="Skills and tools"
                subLabel="Tag this project with verified skills or tools"
                objectSkills={skills}
                selectedSkillIds={skills.map(s => stringToId(s.name))}
                onSelect={handleSelectSkills}
              />
            </View>

            <View as="div" margin="0 0 medium 0">
              <RichTextEdit
                id="project_description"
                label="Project Description"
                content={description}
                onContentChange={handleDescriptionChange}
              />
            </View>
            <View as="div" borderWidth="0 0 small 0" margin="0 0 medium 0">
              <View as="div" margin="0 0 medium 0">
                <Heading
                  level="h2"
                  themeOverride={{h2FontSize: '1.375rem', h2FontWeight: 700}}
                  margin="0 0 small 0"
                >
                  Attachments
                </Heading>
                <View as="div" margin="0 0 medium 0">
                  <FormField
                    id="project_attachments_label"
                    label={
                      <div>
                        <Text as="div" weight="bold" lineHeight="double">
                          Files
                        </Text>
                        <Text as="div" weight="normal">
                          Add any relevant files for the project (25mb max per file)
                        </Text>
                      </div>
                    }
                  >
                    <Button renderIcon={IconAddLine} margin="small 0" onClick={handlePickFiles}>
                      Add Files
                    </Button>
                    {attachments.length > 0 ? <AttachmentsTable attachments={attachments} /> : null}
                  </FormField>
                </View>
                <View as="div" margin="0 0 medium 0">
                  <FormField
                    id="project_links_label"
                    label={
                      <div>
                        <Text as="div" weight="bold" lineHeight="double">
                          Links
                        </Text>
                        <Text as="div" weight="normal" lineHeight="double">
                          Add links to any external URLs
                        </Text>
                        <Flex as="div" direction="column" gap="small" margin="0 0 small 0">
                          {links.map((link: string) =>
                            renderEditLink(link, handleEditLink, handleDeleteLink)
                          )}
                        </Flex>
                      </div>
                    }
                  >
                    <Button renderIcon={IconAddLine} onClick={handleAddLink}>
                      Add a Link
                    </Button>
                  </FormField>
                </View>
              </View>
            </View>
            <View as="div" margin="0 0 medium 0" padding="0 0 medium 0">
              <Heading level="h2" themeOverride={{h2FontSize: '1.375rem', h2FontWeight: 700}}>
                Achievements
              </Heading>
              <Text as="div">
                Associate any badges to this project by selecting from previously earned
                achievements
              </Text>
              <AchievementsEdit
                allAchievements={allAchievements}
                selectedAchievementIds={achievementIds}
                onChange={setAchievementIds}
              />
            </View>
          </View>
          <CoverImageModal
            imageUrl={heroImageUrl}
            open={editCoverImageModalOpen}
            onDismiss={handleCloseEditCoverImageModal}
            onSave={handleSaveHeroImageUrl}
          />
        </form>
      </View>
      <div
        id="footer"
        style={{
          position: 'sticky',
          bottom: '0',
        }}
      >
        <View as="div" background="primary" borderWidth="small 0 0 0">
          <Flex justifyItems="end" padding="small" gap="small">
            <Button onClick={handlePreviewClick}>Preview</Button>
            <Button color="primary" onClick={handleSaveClick}>
              Save
            </Button>
          </Flex>
        </View>
      </div>
      <AddFilesModal
        open={addFilesModalOpen}
        onDismiss={handleCloseFilesModal}
        onSave={handleAddFiles}
      />
    </View>
  )
}

export default ProjectEdit
