/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import React, {memo, useEffect, useRef, useCallback} from 'react'
import {useSelector, useDispatch} from 'react-redux'
import actions from '../actions'
import useStateWithCallback from '@canvas/use-state-with-callback-hook'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Menu, type MenuItem} from '@instructure/ui-menu'
import {IconButton} from '@instructure/ui-buttons'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {
  IconPublishSolid,
  IconTroubleLine,
  IconLockSolid,
  IconOvalHalfSolid,
} from '@instructure/ui-icons'
import type {ReduxState, RolePermission, PermissionModifyAction} from './types'
import {EnabledState} from './types'

const I18n = createI18nScope('permission_button')

// let's cinch up that large margin around the IconButtons so that their
// decorations snuggle up a little closer and are more obviously a part
// of the button itself. Only do this for the table view, though, since
// the tray view is already pretty tight.
const themeOverride = {largeHeight: '1.75rem'}

enum MenuId {
  DEFAULT = 'default',
  PARTIAL = 'partial',
  ENABLED = 'enabled',
  DISABLED = 'disabled',
  LOCKED = 'locked',
}

const ENABLED_STATE_TO_MENU_ID: Record<EnabledState, MenuId> = {
  [EnabledState.NONE]: MenuId.DISABLED,
  [EnabledState.PARTIAL]: MenuId.PARTIAL,
  [EnabledState.ALL]: MenuId.ENABLED,
}

interface PermissionButtonProps {
  inTray: boolean
  permission: RolePermission
  permissionName: string
  permissionLabel: string
  roleLabel?: string
  roleId: string
  onFocus?: () => void
}

function PermissionButton(props: PermissionButtonProps): JSX.Element {
  const {permission, roleId, permissionName, permissionLabel, roleLabel, inTray} = props
  const [showMenu, setShowMenu] = useStateWithCallback<boolean>(false)
  const buttonRef = useRef<HTMLButtonElement | null>(null)

  const apiBusy: boolean = useSelector((s: ReduxState) =>
    s.apiBusy.some(elt => elt.id === roleId && elt.name === permissionName),
  )
  const setFocus: boolean = useSelector((s: ReduxState) => {
    const {targetArea, roleId: nextRoleId, permissionName: nextPermissionName} = s.nextFocus
    const targetFocusButton = permissionName === nextPermissionName && roleId === nextRoleId
    const targetFocusArea = (targetArea === 'tray' && inTray) || (targetArea === 'table' && !inTray)
    return targetFocusButton && targetFocusArea
  })

  const dispatch = useDispatch()
  const handleClick = useCallback(
    (action: PermissionModifyAction) => dispatch(actions.modifyPermissions(action)),
    [dispatch],
  )
  const fixButtonFocus = useCallback(
    (args: Pick<PermissionButtonProps, 'permissionName' | 'roleId' | 'inTray'>) =>
      dispatch(actions.fixButtonFocus(args)),
    [dispatch],
  )
  const cleanFocus = useCallback(() => dispatch(actions.cleanFocus()), [dispatch])

  useEffect(() => {
    if (setFocus && buttonRef.current) {
      buttonRef.current.focus()
      cleanFocus()
    }
  }, [setFocus, cleanFocus])

  function renderAllyScreenReaderTag(): string {
    const {enabled, locked} = permission
    let status: string = ''
    if (enabled === EnabledState.ALL && !locked) {
      status = I18n.t('Enabled')
    } else if (enabled === EnabledState.ALL && locked) {
      status = I18n.t('Enabled and Locked')
    } else if (enabled === EnabledState.PARTIAL && !locked) {
      status = I18n.t('Partially enabled')
    } else if (enabled === EnabledState.PARTIAL && locked) {
      status = I18n.t('Partially enabled and Locked')
    } else if (enabled === EnabledState.NONE && !locked) {
      status = I18n.t('Disabled')
    } else {
      status = I18n.t('Disabled and Locked')
    }
    return `${status} ${permissionLabel} ${roleLabel}`
  }

  function closeMenu(): void {
    setShowMenu(false, function () {
      fixButtonFocus({permissionName, roleId, inTray})
    })
  }

  function toggleMenu(): void {
    if (showMenu) closeMenu()
    else setShowMenu(true)
  }

  function checkedSelection({enabled, locked, explicit}: RolePermission): MenuId[] {
    if (!explicit) return [MenuId.DEFAULT]

    const checked = [ENABLED_STATE_TO_MENU_ID[enabled]]
    if (locked) checked.push(MenuId.LOCKED)
    return checked
  }

  function renderButton(): JSX.Element {
    const {enabled} = permission

    function stateIcon() {
      if (enabled === EnabledState.NONE) return IconTroubleLine
      if (enabled === EnabledState.ALL) return IconPublishSolid
      if (enabled === EnabledState.PARTIAL) return IconOvalHalfSolid
      throw new RangeError('stateIcon parameter is not as expected')
    }

    const stateColor = enabled === EnabledState.NONE ? 'danger' : 'success'

    return (
      <IconButton
        themeOverride={inTray ? undefined : themeOverride}
        elementRef={ref => {
          buttonRef.current = ref as HTMLButtonElement
        }}
        onClick={toggleMenu}
        onFocus={props.onFocus}
        interaction={permission.readonly ? 'disabled' : 'enabled'}
        size="large"
        withBackground={false}
        withBorder={false}
        color={stateColor}
        margin={inTray ? '0' : 'small 0 0 0'}
        screenReaderLabel={renderAllyScreenReaderTag()}
      >
        {stateIcon()}
      </IconButton>
    )
  }

  function renderLockOrSpinner(): JSX.Element {
    const {locked, explicit} = permission
    const flexWidth = inTray ? '22px' : '18px'
    return (
      <Flex direction="column" margin="none none none xx-small" width={flexWidth}>
        <Flex.Item size="24px">
          {locked && explicit && (
            <Text color="primary">
              <IconLockSolid data-testid="permission-button-locked" />
            </Text>
          )}
        </Flex.Item>
        <Flex.Item size="24px">
          {apiBusy && (
            <Spinner
              delay={0}
              size="x-small"
              renderTitle={I18n.t('Waiting for request to complete')}
            />
          )}
        </Flex.Item>
      </Flex>
    )
  }

  function renderMenu(button: JSX.Element): JSX.Element {
    const closeMenuIfInTray = inTray ? () => {} : closeMenu
    const selected = checkedSelection(permission)

    function adjustPermissions({
      enabled,
      locked,
      explicit,
    }: {enabled?: boolean; locked?: boolean; explicit: boolean}): void {
      handleClick({name: permissionName, id: roleId, inTray, enabled, locked, explicit})
    }

    // Since the enum enabled values exist only here on the front end and
    // the backend uses only Booleans for the granular permissions, we
    // will convert them back to Booleans for the API call.
    function menuChange(
      _e: unknown,
      _updated: unknown,
      _selected: unknown,
      selectedMenuItem: MenuItem,
    ): void {
      const value = selectedMenuItem.props.value
      const {locked} = permission

      switch (value) {
        case MenuId.ENABLED:
          adjustPermissions({enabled: true, locked, explicit: true})
          return
        case MenuId.DISABLED:
          adjustPermissions({enabled: false, locked, explicit: true})
          return
        case MenuId.LOCKED:
          // Toggling the locked state also requires us to send along the current
          // overridden enabled value, if any. Otherwise unlocking with an
          // inferred value will just revert to the default, which isn't always
          // what we want.
          if (selected.includes(MenuId.DISABLED))
            adjustPermissions({enabled: false, locked: !locked, explicit: true})
          else if (selected.includes(MenuId.ENABLED))
            adjustPermissions({enabled: true, locked: !locked, explicit: true})
          else adjustPermissions({locked: !locked, explicit: true})
          return
        case MenuId.DEFAULT:
          adjustPermissions({explicit: false})
      }
    }

    return (
      <Menu
        placement="bottom center"
        trigger={button}
        defaultShow={!inTray}
        shouldFocusTriggerOnClose={false}
        onSelect={closeMenuIfInTray}
        onDismiss={closeMenuIfInTray}
        onBlur={closeMenuIfInTray}
      >
        <Menu.Group label="" selected={selected} onSelect={menuChange}>
          {/* "partially enabled" callout removed for now per Product until they can decide on wording
              {selected.includes(MenuId.PARTIAL) && [
                <Menu.Item id="permission_table_partial_menu_item" value={MenuId.PARTIAL} disabled>
                  <Text>{I18n.t('Partially Enabled')}</Text>
                </Menu.Item>,
                <Menu.Separator />
              ]}
              */}
          <Menu.Item id="permission_table_enable_menu_item" value={MenuId.ENABLED}>
            <Text>{I18n.t('Enable')}</Text>
          </Menu.Item>
          <Menu.Item id="permission_table_disable_menu_item" value={MenuId.DISABLED}>
            <Text>{I18n.t('Disable')}</Text>
          </Menu.Item>
          <Menu.Item id="permission_table_lock_menu_item" value={MenuId.LOCKED}>
            <Text>{I18n.t('Lock')}</Text>
          </Menu.Item>
          <Menu.Separator />
          <Menu.Item id="permission_table_use_default_menu_item" value={MenuId.DEFAULT}>
            <Text>{I18n.t('Use Default')}</Text>
          </Menu.Item>
        </Menu.Group>
      </Menu>
    )
  }

  const button = renderButton()

  // Note: for performance, we do not initialize the menu button at all until
  //       the button is clicked, unless we are in a tray (which has significatnly
  //       less buttons). The reason we do something different if the button is
  //       in the tray is because focus is able to escape from the tray if we
  //       do it the other way, and performance of the tray is not currently
  //       an issue.
  return (
    <div
      id={`${props.permissionName}_${props.roleId}`}
      className="ic-permissions__permission-button-container"
    >
      <div>{inTray || showMenu ? renderMenu(button) : button}</div>
      {renderLockOrSpinner()}
    </div>
  )
}

export default memo(PermissionButton)
