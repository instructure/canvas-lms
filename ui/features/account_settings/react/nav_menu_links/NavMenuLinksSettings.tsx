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
import {getActiveCanvasTheme} from '@canvas/react'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {Button, IconButton} from '@instructure/ui-buttons'
import {IconExternalLinkLine, IconLinkLine, IconTrashLine} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {
  useNavMenuLinksStore,
  type NavMenuLink,
  type NavMenuPlacements,
} from './useNavMenuLinksStore'
import {useState} from 'react'
import {AddLinkModal} from '@canvas/nav-menu-links/react/components/AddLinkModal'
import {Tag} from '@instructure/ui-tag'
import {confirmDanger} from '@instructure/platform-instui-bindings'

const I18n = createI18nScope('account_settings')

declare const ENV: {
  PERMISSIONS?: {
    manage_nav_menu_links?: boolean
  }
}

/**
 * Manage NavMenuLinks with an account context (i.e., for all courses in the account)
 * Note: NavMenuLinks with a course context are managed by CourseNavigationSettings.
 */
export default function NavMenuLinksSettings(): JSX.Element {
  const [isAddLinkModalOpen, setIsAddLinkModalOpen] = useState(false)
  const {links, appendLink, deleteLink} = useNavMenuLinksStore()

  return (
    <View>
      <h2 id="custom-links" className="screenreader-only">
        {I18n.t('Custom Links')}
      </h2>
      <legend>{I18n.t('Custom Links')}</legend>
      <ul className="ic-Sortable-list">
        {links.map((link, index) => (
          <NavMenuLink
            key={index}
            label={link.label}
            url={link.url}
            placements={link.placements}
            onDeleteRequest={async () => {
              if (
                await confirmDanger({
                  title: I18n.t('Delete Custom Link'),
                  heading: I18n.t('You are about to delete "%{label}".', {label: link.label}),
                  message: (
                    <>
                      <Text as="p">{I18n.t('Are you sure you want to delete this link?')}</Text>
                      <Text as="p" size="small" color="secondary">
                        {I18n.t('Remember to save your settings for this change to take effect.')}
                      </Text>
                    </>
                  ),
                  confirmButtonLabel: I18n.t('Delete'),
                  cancelButtonLabel: I18n.t('Cancel'),
                  closeButtonLabel: I18n.t('Close'),
                  theme: getActiveCanvasTheme(),
                })
              ) {
                deleteLink(index)
              }
            }}
          />
        ))}
      </ul>
      {ENV.PERMISSIONS?.manage_nav_menu_links && (
        <View as="div" padding="medium 0 0 0">
          <Button type="button" onClick={() => setIsAddLinkModalOpen(true)}>
            {I18n.t('Add a Link')}
          </Button>
          {isAddLinkModalOpen && (
            <AddLinkModal
              onDismiss={() => setIsAddLinkModalOpen(false)}
              onAdd={appendLink}
              availablePlacements={['course_nav', 'account_nav', 'user_nav']}
            />
          )}
        </View>
      )}
      <input type="hidden" name="account[nav_menu_links]" value={JSON.stringify(links)} />
    </View>
  )
}

type NavMenuPlacementKey = keyof NavMenuPlacements

const ALL_PLACEMENTS: NavMenuPlacementKey[] = ['course_nav', 'account_nav', 'user_nav']

const PLACEMENT_LABELS: Record<NavMenuPlacementKey, () => string> = {
  course_nav: () => I18n.t('Course Navigation'),
  account_nav: () => I18n.t('Account Navigation'),
  user_nav: () => I18n.t('User Navigation'),
}

type NavMenuLinkProps = {
  label: string
  url: string
  placements: NavMenuPlacements
  onDeleteRequest: () => void
}

function NavMenuLink({label, url, placements, onDeleteRequest}: NavMenuLinkProps): JSX.Element {
  return (
    <li className="ic-Sortable-item">
      <div className="ic-Sortable-item__Text">
        <Flex alignItems="center" gap="x-small" wrap="wrap" width="100%">
          <Flex.Item>
            <IconLinkLine size="x-small" />
          </Flex.Item>
          <Flex.Item margin="0 xx-small 0 xxx-small" shouldGrow shouldShrink size="0">
            <Text wrap="break-word">{label}</Text>
            {url && (
              <Text as="div" size="x-small" color="secondary" wrap="break-word">
                <Link
                  href={url}
                  target="_blank"
                  rel="noreferrer"
                  isWithinText={false}
                  elementRef={el => {
                    // as of Apr 2026, external_links.js adds icons inconsistently (not to newly rendered links), so we add it manually
                    el?.classList.add('exclude_external_icon')
                  }}
                  renderIcon={IconExternalLinkLine}
                  iconPlacement="end"
                >
                  {url}
                </Link>
              </Text>
            )}
          </Flex.Item>
          {ALL_PLACEMENTS.map(
            p =>
              placements[p] && (
                <Flex.Item key={p}>
                  <Tag text={PLACEMENT_LABELS[p]()} />
                </Flex.Item>
              ),
          )}
        </Flex>
      </div>
      {ENV.PERMISSIONS?.manage_nav_menu_links && (
        <div className="ic-Sortable-item__Actions">
          <IconButton
            screenReaderLabel={I18n.t('Delete %{linkLabel}', {linkLabel: label})}
            size="small"
            withBackground={false}
            withBorder={false}
            renderIcon={IconTrashLine}
            data-pendo="navigation-menu-delete"
            onClick={onDeleteRequest}
          />
        </div>
      )}
    </li>
  )
}
