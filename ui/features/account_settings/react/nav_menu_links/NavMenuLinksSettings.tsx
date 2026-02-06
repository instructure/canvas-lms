/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Button, IconButton} from '@instructure/ui-buttons'
import {IconMoreSolid, IconLinkLine, IconTrashLine} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {Flex} from '@instructure/ui-flex'
import {useNavMenuLinksStore} from './useNavMenuLinksStore'
import {useState} from 'react'
import {AddLinkModal} from '@canvas/nav-menu-links/react/components/AddLinkModal'
import {Tag} from '@instructure/ui-tag'

const I18n = createI18nScope('account_settings')

/**
 * Manage NavMenuLinks with an account context (i.e., for all courses in the account)
 * Note: NavMenuLinks with a course context are managed by CourseNavigationSettings.
 */
export default function NavMenuLinksSettings(): JSX.Element {
  const [isAddLinkModalOpen, setIsAddLinkModalOpen] = useState(false)
  const {links, appendLink, deleteLink} = useNavMenuLinksStore()

  return (
    <View>
      <h2 id="custom-links" className="screenreader-only">{I18n.t('Custom Links')}</h2>
      <legend>{I18n.t('Custom Links')}</legend>
      <ul className="ic-Sortable-list">
        {links.map((link, index) => (
          <NavMenuLink key={index} label={link.label} onDelete={() => deleteLink(index)} />
        ))}
      </ul>
      <View as="div" padding="medium 0 0 0">
        <Button type="button" onClick={() => setIsAddLinkModalOpen(true)}>
          {I18n.t('Add a Link')}
        </Button>
        {isAddLinkModalOpen && (
          <AddLinkModal onDismiss={() => setIsAddLinkModalOpen(false)} onAdd={appendLink} />
        )}
      </View>
      <input type="hidden" name="account[nav_menu_links]" value={JSON.stringify(links)} />
    </View>
  )
}

type NavMenuLinkProps = {
  label: string
  onDelete: () => void
}

function NavMenuLink({label, onDelete}: NavMenuLinkProps): JSX.Element {
  return (
    <li className="ic-Sortable-item">
      <div className="ic-Sortable-item__Text">
        <Flex alignItems="center" gap="x-small">
          <Flex.Item>
            <IconLinkLine size="x-small" />
          </Flex.Item>
          <Flex.Item margin="0 xx-small 0 xxx-small">
            <Text>{label}</Text>
          </Flex.Item>
          <Flex.Item>
            <Tag text={I18n.t('Course Navigation')} />
          </Flex.Item>
        </Flex>
      </div>
      <div className="ic-Sortable-item__Actions">
        <Menu
          trigger={
            <IconButton
              screenReaderLabel={I18n.t('Settings for %{linkLabel}', {linkLabel: label})}
              size="small"
              withBackground={false}
              withBorder={false}
              renderIcon={IconMoreSolid}
            />
          }
        >
          <Menu.Item data-pendo="navigation-menu-delete" onClick={onDelete} type="button">
            <Flex>
              <Flex.Item padding="0 x-small 0 0" margin="0 0 xxx-small 0">
                <IconTrashLine />
              </Flex.Item>
              <Flex.Item>{I18n.t('Delete')}</Flex.Item>
            </Flex>
          </Menu.Item>
        </Menu>
      </div>
    </li>
  )
}
NavMenuLink.displayName = 'NavMenuLink'
