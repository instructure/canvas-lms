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

import Backbone from '@canvas/backbone'
import $ from 'jquery'
import 'jquery-migrate'
import AdminToolsView from '../AdminToolsView'
import {waitFor} from '@testing-library/dom'

describe('AdminToolsView', () => {
  let adminToolsView
  let container

  beforeEach(() => {
    container = document.createElement('div')
    container.id = 'fixtures'
    document.body.appendChild(container)

    adminToolsView = new AdminToolsView({
      restoreContentPaneView: new Backbone.View(),
      messageContentPaneView: new Backbone.View(),
      loggingContentPaneView: new Backbone.View(),
      tabs: {
        courseRestore: true,
        viewMessages: true,
        logging: true,
      },
    })
    $(container).append(adminToolsView.render().el)
  })

  afterEach(() => {
    adminToolsView.remove()
    container.remove()
  })

  it('should be accessible', async () => {
    await waitFor(() => {
      expect(adminToolsView.$adminToolsTabs).toBeTruthy()
    })
  })

  it('initializes jquery tabs', () => {
    expect(adminToolsView.$adminToolsTabs.data('ui-tabs')).toBeTruthy()
  })

  it('renders tabs based on configuration', () => {
    const tabs = adminToolsView.$adminToolsTabs.find('[role="tab"]')
    expect(tabs).toHaveLength(2)
  })

  it('renders content panes for each tab', () => {
    const panes = adminToolsView.$adminToolsTabs.find('[role="tabpanel"]')
    expect(panes).toHaveLength(2)
  })

  it('renders the correct tabs', () => {
    const tabLabels = adminToolsView.$adminToolsTabs
      .find('[role="tab"] .ui-tabs-anchor')
      .map((_, el) => $(el).text())
      .get()
    expect(tabLabels).toContain('View Notifications')
    expect(tabLabels).toContain('Logging')
  })
})
