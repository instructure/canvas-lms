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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import ConnectedFriendlyDatetimes from '../ConnectedFriendlyDatetimes'
import {render} from '@testing-library/react'

const I18n = useI18nScope('assignments_2')

describe('ConnectedFriendlyDatetimes', () => {
  const defaultProps = {
    firstDateTime: '2022-07-10T23:00:00-00:00',
    secondDateTime: '2022-07-22T23:00:00-00:00',
  }

  it('it renders when the dates are strings', () => {
    const {getAllByText} = render(<ConnectedFriendlyDatetimes {...defaultProps} />)

    expect(getAllByText('Jul 10, 2022 Jul 22, 2022')).toHaveLength(2)
  })

  it('it renders when the dates are Dates', () => {
    const props = {
      firstDateTime: new Date('2022-07-10T23:00:00-00:00'),
      secondDateTime: new Date('2022-07-22T23:00:00-00:00'),
    }

    const {getAllByText} = render(<ConnectedFriendlyDatetimes {...props} />)

    expect(getAllByText('Jul 10, 2022 Jul 22, 2022')).toHaveLength(2)
  })

  it('renders a prefix', () => {
    const {getAllByText} = render(<ConnectedFriendlyDatetimes prefix="yo:" {...defaultProps} />)

    expect(getAllByText('yo: Jul 10, 2022 Jul 22, 2022')).toHaveLength(2)
  })

  it('renders a mobile prefix', () => {
    const {getAllByText} = render(
      <ConnectedFriendlyDatetimes prefixMobile="mobile: " {...defaultProps} />
    )

    expect(getAllByText('mobile: 7/10/2022 7/22/2022')).toHaveLength(1)
  })

  it('renders a connector', () => {
    const {getAllByText} = render(<ConnectedFriendlyDatetimes connector="to" {...defaultProps} />)

    expect(getAllByText('Jul 10, 2022 to Jul 22, 2022')).toHaveLength(2)
  })

  it('renders a mobile connector', () => {
    const {getAllByText} = render(
      <ConnectedFriendlyDatetimes connectorMobile="mobile" {...defaultProps} />
    )

    expect(getAllByText('7/10/2022 mobile 7/22/2022')).toHaveLength(1)
  })

  it('shows the time when requested', () => {
    const props = {showTime: true, ...defaultProps}
    const {getAllByText} = render(<ConnectedFriendlyDatetimes {...props} />)

    expect(getAllByText('Jul 10, 2022 at 11pm Jul 22, 2022 at 11pm')).toHaveLength(2)
  })

  it('it uses a specified format', () => {
    const {getAllByText} = render(
      <ConnectedFriendlyDatetimes format={I18n.t('#date.formats.full')} {...defaultProps} />
    )

    expect(getAllByText('Jul 10, 2022 11:00pm Jul 22, 2022 11:00pm')).toHaveLength(2)
  })
})
