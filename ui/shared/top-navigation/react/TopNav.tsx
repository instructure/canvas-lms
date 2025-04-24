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

import React, {useEffect, useState} from 'react'
import {InstUISettingsProvider} from '@instructure/emotion'
import {TopNavBar} from '@instructure/ui-top-nav-bar'
import {Breadcrumb} from '@instructure/ui-breadcrumb'
import {canvas} from '@instructure/ui-themes'
import useToggleCourseNav from './hooks/useToggleCourseNav'
import {useMutation, useQueryClient} from '@tanstack/react-query'
import {setSetting} from '@canvas/settings-query/react/settingsQuery'
import type {ItemChild} from '@instructure/ui-top-nav-bar/types/TopNavBar/props'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {EnvCommon} from '@canvas/global/env/EnvCommon'

type Crumb = NonNullable<EnvCommon['breadcrumbs']>[0]

const overrides = {
  componentOverrides: {
    Link: {
      color: canvas.colors.contrasts.blue5782,
    },
    [TopNavBar.Layout.componentId]: {
      desktopBackgroundInverse: canvas.colors.contrasts?.grey1111 ?? 'white',
      smallViewportBackgroundInverse: canvas.colors.contrasts?.grey1111 ?? 'white',
      desktopZIndex: 99,
      smallViewportZIndex: 99,
      smallViewportTrayZIndex: 99,
    },
  },
}

export interface ITopNavProps {
  actionItems?: ItemChild[]
  getBreadCrumbSetter?: (funcs: {
    getCrumbs: () => Crumb[]
    setCrumbs: (crumbs: Crumb | Crumb[]) => void
  }) => void
}

const TopNav: React.FC<ITopNavProps> = ({actionItems, getBreadCrumbSetter}) => {
  // @ts-expect-error
  const [breadCrumbs, setBreadCrumbs] = useState<Crumb[]>(window.ENV.breadcrumbs)
  const queryClient = useQueryClient()
  const I18n = createI18nScope('react_top_nav')

  const {toggle} = useToggleCourseNav()

  const setCollapseGlobalNav = useMutation({
    mutationFn: setSetting,
    onSuccess: () =>
      queryClient.invalidateQueries({
        queryKey: ['settings', 'collapse_course_nav'],
      }),
  })

  function updateCollapseGlobalNav(newState: boolean) {
    setCollapseGlobalNav.mutate({
      setting: 'collapse_course_nav',
      newState,
    })
  }

  const handleToggleGlobalNav = (): void => {
    const isExpanded = toggle()
    updateCollapseGlobalNav(!isExpanded)
  }

  // If the `getBreadcrumbSetter` prop is passed, we call it with an object
  // containing two functions: `getCrumbs` and `setCrumbs`. The former returns
  // the current breadcrumbs, and the latter sets the breadcrumbs. If the setter
  // is called with a Crumb object, that will just replace the last crumb in the
  // list. If it's called with an array of Crumb objects, it will replace all
  // the crumbs.
  useEffect(function () {
    if (getBreadCrumbSetter) {
      const getCrumbs = () => breadCrumbs
      const setCrumbs = (newCrumbs: Crumb | Crumb[]) => {
        if (Array.isArray(newCrumbs)) {
          setBreadCrumbs(newCrumbs)
        } else {
          // @ts-expect-error
          setBreadCrumbs(crumbs => {
            if (crumbs) {
              const oldCrumbs = crumbs.length > 1 ? crumbs.slice(0, -1) : crumbs
              return [...oldCrumbs, newCrumbs]
            }
          })
        }
      }
      getBreadCrumbSetter({getCrumbs, setCrumbs})
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return (
    <InstUISettingsProvider theme={overrides}>
      <TopNavBar inverseColor={true} width="100%">
        {() => (
          <TopNavBar.Layout
            navLabel="Top Navigation"
            smallViewportConfig={{
              dropdownMenuToggleButtonLabel: 'Toggle Menu',
              dropdownMenuLabel: 'Main Menu',
            }}
            renderBreadcrumb={
              breadCrumbs?.length > 0 ? (
                <TopNavBar.Breadcrumb onClick={() => handleToggleGlobalNav()}>
                  <Breadcrumb label="test">
                    {breadCrumbs?.map(crumb => {
                      const url = crumb.url ?? undefined
                      return (
                        <Breadcrumb.Link key={crumb.name} href={url}>
                          {crumb.name}
                        </Breadcrumb.Link>
                      )
                    })}
                  </Breadcrumb>
                </TopNavBar.Breadcrumb>
              ) : undefined
            }
            renderActionItems={
              <TopNavBar.ActionItems
                listLabel="Actions"
                renderHiddenItemsMenuTriggerLabel={hiddenChildrenCount =>
                  I18n.t('%{hiddenChildrenCount} more actions', {
                    hiddenChildrenCount,
                  })
                }
              >
                {actionItems?.map(component => component)}
              </TopNavBar.ActionItems>
            }
          />
        )}
      </TopNavBar>
    </InstUISettingsProvider>
  )
}

export default TopNav
