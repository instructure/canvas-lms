/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import React, {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Spinner} from '@instructure/ui-spinner'
import {Alert} from '@instructure/ui-alerts'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {Flex} from '@instructure/ui-flex'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Table} from '@instructure/ui-table'
import {
  IconMoreLine,
  IconUserLine,
  IconAddFolderLine,
  IconTextLine,
  IconTrashLine,
  IconSettingsLine,
  IconSortLine,
} from '@instructure/ui-icons'
import PortfolioSettingsModal from './PortfolioSettingsModal'
import {Menu} from '@instructure/ui-menu'
import SectionEditModal from './SectionEditModal'
import type {ePortfolio, ePortfolioSection} from './types'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('eportfolio')
interface Props {
  readonly portfolio: ePortfolio
  readonly isOwner: boolean
  readonly onConfirm: () => void
  readonly sections: ePortfolioSection[]
}

function SectionList(props: Props) {
  const [modalType, setModalType] = useState('')
  const [selectedSection, setSelectedSection] = useState<ePortfolioSection | null>(null)
  const [isEditPortfolio, setIsEditPortfolio] = useState(false)
  const [portfolioName, setPortfolioName] = useState(props.portfolio.name)
  const [portfolioPublic, setPortfolioPublic] = useState(props.portfolio.public)

  const onPortfolioUpdate = (name: string, isPublic: boolean) => {
    setPortfolioName(name)
    setPortfolioPublic(isPublic)
    onConfirm()
  }

  const onConfirm = () => {
    setModalType('')
    setSelectedSection(null)
    setIsEditPortfolio(false)
    props.onConfirm()
  }

  const onCancel = () => {
    setModalType('')
    setSelectedSection(null)
    setIsEditPortfolio(false)
  }

  const onMenuSelect = (section: ePortfolioSection, type: string) => {
    if (section != null) {
      setSelectedSection(section)
    }
    setModalType(type)
  }
  const renderModal = () => {
    if (modalType !== '') {
      return (
        <SectionEditModal
          modalType={modalType}
          section={selectedSection}
          sectionList={props.sections ?? []}
          onConfirm={onConfirm}
          onCancel={onCancel}
          portfolio={{...props.portfolio, name: portfolioName}}
        />
      )
    }
  }
  const renderSectionRow = (section: ePortfolioSection) => {
    const options = [
      <Menu.Item
        key="rename"
        data-testid="rename-menu-option"
        onClick={() => onMenuSelect(section, 'rename')}
      >
        <Flex direction="row" gap="x-small">
          <IconTextLine />
          {I18n.t('Rename')}
        </Flex>
      </Menu.Item>,
    ]
    if (props.sections && props.sections.length > 1) {
      options.push(
        <Menu.Item
          key="move"
          data-testid="move-menu-option"
          onClick={() => onMenuSelect(section, 'move')}
        >
          <Flex direction="row" gap="x-small">
            <IconSortLine />
            {I18n.t('Move to...')}
          </Flex>
        </Menu.Item>,
      )
      options.push(
        <Menu.Item
          key="delete"
          data-testid="delete-menu-option"
          onClick={() => onMenuSelect(section, 'delete')}
        >
          <Flex direction="row" gap="x-small">
            <IconTrashLine />
            {I18n.t('Delete')}
          </Flex>
        </Menu.Item>,
      )
    }
    return (
      <Table.Row key={section.id}>
        <Table.Cell>
          <Link href={section.category_url}>
            <Text size="small">{section.name}</Text>
          </Link>
        </Table.Cell>
        <Table.Cell>
          {props.isOwner ? (
            <Menu
              trigger={
                <IconButton
                  data-testid={`${section.id}-menu`}
                  withBorder={false}
                  size="small"
                  screenReaderLabel={I18n.t('Options for %{sectionName}', {
                    sectionName: section.name,
                  })}
                >
                  <IconMoreLine />
                </IconButton>
              }
            >
              {options}
            </Menu>
          ) : null}
        </Table.Cell>
      </Table.Row>
    )
  }

  return (
    <Flex direction="column" gap="x-small">
      <Text size="large" weight="bold">
        {portfolioName}
      </Text>
      <Text>{I18n.t('Sections')}</Text>
      <View display="block" overflowY="auto" maxHeight="400px">
        <div id="section_list">
          <Table
            caption={I18n.t('List of sections for %{eportfolio}', {
              eportfolio: props.portfolio.name,
            })}
          >
            <Table.Body>
              {(props.sections ?? []).map((section: ePortfolioSection) => {
                return renderSectionRow(section)
              })}
            </Table.Body>
          </Table>
        </div>
      </View>
      {props.isOwner ? (
        <>
          <Button
            textAlign="start"
            renderIcon={<IconAddFolderLine />}
            data-testid="add-section-button"
            onClick={() => setModalType('add')}
          >
            {I18n.t('Add Section')}
          </Button>
          <span className="portfolio_settings_link">
            <Button
              display="block"
              data-testid="portfolio-settings"
              textAlign="start"
              renderIcon={<IconSettingsLine />}
              onClick={() => setIsEditPortfolio(true)}
            >
              {I18n.t('Settings')}
            </Button>
          </span>
          {renderModal()}
        </>
      ) : null}
      {props.portfolio.profile_url !== null ? (
        <Button
          data-testid="user-profile"
          textAlign="start"
          renderIcon={<IconUserLine />}
          href={props.portfolio.profile_url}
        >
          {I18n.t('User Profile')}
        </Button>
      ) : null}
      {isEditPortfolio ? (
        <PortfolioSettingsModal
          portfolio={{...props.portfolio, name: portfolioName, public: portfolioPublic}}
          onConfirm={(name, isPublic) => onPortfolioUpdate(name, isPublic)}
          onCancel={onCancel}
        />
      ) : null}
    </Flex>
  )
}
export default SectionList
