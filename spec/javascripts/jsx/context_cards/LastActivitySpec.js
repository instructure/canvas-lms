/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import ReactDOM from 'react-dom'
import TestUtils from 'react-dom/test-utils'
import LastActivity from '@canvas/context-cards/react/LastActivity'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'

QUnit.module('StudentContextTray/LastActivity', hooks => {
  let subject
  hooks.afterEach(() => {
    if (subject) {
      const componentNode = ReactDOM.findDOMNode(subject)
      if (componentNode) {
        ReactDOM.unmountComponentAtNode(componentNode.parentNode)
      }
    }
    subject = null
  })

  const lastActivity = 'Wed, 16 Nov 2016 00:29:34 UTC +00:00'

  QUnit.module('lastActivity', () => {
    test('returns null by default', () => {
      subject = TestUtils.renderIntoDocument(<LastActivity user={{}} />)
      notOk(subject.lastActivity)
    })

    test('returns last activity from collection of enrollment last_activity_at', () => {
      const firstActivity = 'Mon, 14 Nov 2016 00:29:34 UTC +00:00'
      const middleActivity = 'Tue, 15 Nov 2016 00:29:34 UTC +00:00'

      subject = TestUtils.renderIntoDocument(
        <LastActivity
          user={{
            enrollments: [
              {
                last_activity_at: lastActivity,
              },
              {
                last_activity_at: firstActivity,
              },
              {
                last_activity_at: middleActivity,
              },
            ],
          }}
        />
      )

      equal(subject.lastActivity, lastActivity)
    })
  })

  test('renders nothing by default', () => {
    subject = TestUtils.renderIntoDocument(<LastActivity user={{}} />)

    throws(() => {
      TestUtils.findRenderedComponentWithType(subject, FriendlyDatetime)
    })
  })

  test('renders friendy date time field when user is present', () => {
    subject = TestUtils.renderIntoDocument(
      <LastActivity
        user={{
          enrollments: [
            {
              last_activity_at: lastActivity,
            },
          ],
        }}
      />
    )

    const friendlyDatetime = TestUtils.findRenderedComponentWithType(subject, FriendlyDatetime)
    equal(friendlyDatetime.props.dateTime, lastActivity)
  })
})
