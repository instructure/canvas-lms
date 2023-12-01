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
import {Avatar} from '@instructure/ui-avatar'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Img} from '@instructure/ui-img'
import {IconAddLine, IconEditLine, IconSearchLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {View} from '@instructure/ui-view'
import {TextArea} from '@instructure/ui-text-area'
import {TextInput} from '@instructure/ui-text-input'
import type {ViewProps} from '@instructure/ui-view'

import SkillSelect from '../../../shared/SkillSelect'
import CoverImageModal from '../../../shared/CoverImageModal'
import type {PortfolioDetailData, SkillData} from '../../../types'
import {renderEditLink, stringToId} from '../../../shared/utils'

type PersonalInfoProps = {
  portfolio: PortfolioDetailData
}

const PersonalInfo = ({portfolio}: PersonalInfoProps) => {
  const {blurb, city, state, phone, email, about} = portfolio
  const [heroImageUrl, setHeroImageUrl] = useState(portfolio.heroImageUrl)
  const [links, setLinks] = useState(portfolio.links)
  const [skills, setSkills] = useState(portfolio.skills)
  const [editCoverImageModalOpen, setEditCoverImageModalOpen] = useState(false)

  const [expanded, setExpanded] = useState(true)

  const handleToggle = useCallback((_event: React.MouseEvent, toggleExpanded: boolean) => {
    setExpanded(toggleExpanded)
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

  const handleSelectSkills = useCallback((newSkills: SkillData[]) => {
    setSkills(newSkills)
  }, [])

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

  return (
    <>
      <ToggleDetails
        summary={
          <View as="div" margin="small 0">
            <Heading level="h2" themeOverride={{h2FontSize: '1.375rem'}}>
              Personal Information
            </Heading>
          </View>
        }
        variant="filled"
        expanded={expanded}
        onToggle={handleToggle}
      >
        <Flex as="div" direction="column" gap="large" margin="medium 0">
          <div
            style={{
              position: 'relative',
              height: '184px',
              background: '#C7CDD1',
              overflow: 'hidden',
            }}
          >
            {heroImageUrl ? <Img src={heroImageUrl} alt="Cover image" constrain="cover" /> : null}
            <div style={{position: 'absolute', right: '12px', bottom: '12px'}}>
              <Button renderIcon={IconEditLine} onClick={handleEditCoverImageClick}>
                Edit cover image
              </Button>
            </div>
            <input type="hidden" name="heroImageUrl" value={heroImageUrl || ''} />
          </div>

          <Flex gap="large">
            <View as="div" position="relative">
              <Avatar
                size="xx-large"
                name={ENV.current_user.display_name}
                renderIcon={
                  ENV.current_user.avatar_image_url ? (
                    <Img src={ENV.current_user.avatar_image_url} />
                  ) : undefined
                }
              />
              <div style={{position: 'absolute', right: '-.5rem', bottom: '-.5rem'}}>
                <IconButton
                  screenReaderLabel="Edit profile image"
                  renderIcon={IconEditLine}
                  size="small"
                />
              </div>
            </View>
            <Flex.Item shouldGrow={true}>
              <View as="div" margin="0 0 small 0">
                <Text as="div" size="x-large" weight="bold">
                  {ENV.current_user.display_name}
                </Text>
              </View>
              <TextInput
                name="blurb"
                renderLabel="Personal headline"
                placeholder="Enter a headline"
                width="20rem"
                size="small"
                defaultValue={blurb}
              />
            </Flex.Item>
          </Flex>

          <View as="div" background="secondary" padding="small">
            <Flex gap="medium">
              <TextInput
                name="city"
                renderLabel="City"
                placeholder="Select city"
                size="small"
                renderAfterInput={IconSearchLine}
                defaultValue={city}
              />
              <TextInput
                name="state"
                renderLabel="State"
                placeholder="Select state"
                size="small"
                renderAfterInput={IconSearchLine}
                defaultValue={state}
              />
              <TextInput
                name="phone"
                renderLabel="Phone"
                placeholder="Enter phone"
                size="small"
                defaultValue={phone}
              />
              <TextInput
                name="email"
                renderLabel="Email address"
                placeholder="Enter email"
                size="small"
                defaultValue={email}
              />
            </Flex>
          </View>
          <View as="div">
            {/* should probably be an RCE */}
            <TextArea
              name="about"
              label="About"
              defaultValue={about.replace(/(\n|\s)+/g, ' ').trim()}
            />
          </View>
          <View as="div" margin="medium 0 0 0">
            <input type="hidden" name="skills" value={JSON.stringify(skills)} />
            <SkillSelect
              label="Skills"
              objectSkills={skills}
              selectedSkillIds={skills.map(s => stringToId(s.name))}
              onSelect={handleSelectSkills}
            />
          </View>
          <View as="div">
            <Text as="p" weight="bold" themeOverride={{paragraphMargin: '1rem 0'}}>
              Links
            </Text>
            <Text as="p" themeOverride={{paragraphMargin: '1rem 0'}}>
              Add any additional links such as a personal website, social media profile, or
              publications
            </Text>
            <Flex as="div" direction="column" gap="small" margin="0 0 small 0">
              {links.map((link: string) => renderEditLink(link, handleEditLink, handleDeleteLink))}
            </Flex>
            <Button renderIcon={IconAddLine} onClick={handleAddLink}>
              Add a Link
            </Button>
          </View>
        </Flex>
      </ToggleDetails>
      <CoverImageModal
        subTitle="Upload and edit a decorative cover image for your profile."
        imageUrl={heroImageUrl}
        open={editCoverImageModalOpen}
        onDismiss={handleCloseEditCoverImageModal}
        onSave={handleSaveHeroImageUrl}
      />
    </>
  )
}

export default PersonalInfo
