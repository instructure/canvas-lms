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

import React from 'react'
import {Img} from '@instructure/ui-img'
import {Responsive} from '@instructure/ui-responsive'
import {TopNavBar} from '@instructure/ui-top-nav-bar'
import {useNewLogin} from '../context/NewLoginContext'
import {useScope as useI18nScope} from '@canvas/i18n'

// @ts-expect-error
import CanvasLmsLogoIcon from '../assets/images/canvas-logo-small.svg'
// @ts-expect-error
import CanvasLmsLogo from '../assets/images/canvas-logo.svg'

const I18n = useI18nScope('new_login')

const AppNavBar = () => {
  const {enableCourseCatalog} = useNewLogin()

  return (
    <TopNavBar breakpoint={10} inverseColor={true}>
      {() => {
        return (
          <TopNavBar.Layout
            navLabel={I18n.t('Login page navigation')}
            smallViewportConfig={{
              dropdownMenuToggleButtonLabel: I18n.t('Menu'),
            }}
            renderBrand={
              <TopNavBar.Brand
                screenReaderLabel={I18n.t('Canvas LMS')}
                renderIcon={
                  <Responsive
                    match="media"
                    query={{
                      small: {minWidth: '48rem'},
                    }}
                  >
                    {(_props, matches) => {
                      if (matches?.includes('small')) {
                        return (
                          <Img
                            src={CanvasLmsLogo}
                            alt={I18n.t('Canvas LMS Logo')}
                            width="8rem"
                            height="2.375rem"
                            constrain="contain"
                          />
                        )
                      } else {
                        return (
                          <Img
                            src={CanvasLmsLogoIcon}
                            alt={I18n.t('Canvas LMS Logo')}
                            width="2.375rem"
                            height="2.375rem"
                            constrain="contain"
                          />
                        )
                      }
                    }}
                  </Responsive>
                }
              />
            }
            renderActionItems={
              enableCourseCatalog ? (
                <TopNavBar.ActionItems
                  listLabel={I18n.t('Page navigation')}
                  renderHiddenItemsMenuTriggerLabel={hiddenChildrenCount =>
                    I18n.t('%{hiddenChildrenCount} More', {hiddenChildrenCount})
                  }
                >
                  <TopNavBar.Item id="browseCourses" href="/search/all_courses">
                    {I18n.t('Browse courses')}
                  </TopNavBar.Item>
                </TopNavBar.ActionItems>
              ) : undefined
            }
          />
        )
      }}
    </TopNavBar>
  )
}

export default AppNavBar
