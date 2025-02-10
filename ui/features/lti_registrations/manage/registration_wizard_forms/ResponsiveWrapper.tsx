import {Modal} from '@instructure/ui-modal'
import {Responsive} from '@instructure/ui-responsive'
/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

export type ResponsiveWrapperPassthroughProps = {
  size: 'fullscreen' | 'medium'
  spacing?: 'compact'
  offset: 'small' | 'medium'
}

export const ResponsiveWrapper = ({
  render,
}: {render: (modalProps?: ResponsiveWrapperPassthroughProps | null) => React.ReactNode}) => {
  return (
    <Responsive
      match="media"
      query={{
        // A good rough estimation for mobile/tablet is 768px, or 48rem with 1rem=16px
        mobile: {maxWidth: '48rem'},
        desktop: {minWidth: '48rem'},
      }}
      props={{
        mobile: {
          size: 'fullscreen',
          spacing: 'compact',
          offset: 'small',
        },
        desktop: {
          size: 'medium',
          spacing: undefined,
          offset: 'medium',
        },
      }}
      render={props => {
        // the passthrough props are not typed very well, so we need to cast them
        return render(props as ResponsiveWrapperPassthroughProps)
      }}
    ></Responsive>
  )
}
