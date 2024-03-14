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
import {render, fireEvent} from '@testing-library/react'
import ContextModulesHeader from '../ContextModulesHeader'

const defaultProps = {
  title: 'Modules',
  publishMenu: {
    courseId: '1',
    runningProgressId: null,
    disabled: false,
    visible: true,
  },
  viewProgress: {
    label: 'View Progress',
    url: '/courses/1/modules/progress',
    visible: true,
  },
  expandCollapseAll: {
    label: 'Collapse All',
    dataUrl: '/courses/1/modules/expand_collapse_all',
    dataExpand: false,
    ariaExpanded: false,
    ariaLabel: 'Collapse All',
  },
  addModule: {
    label: 'Add Module',
    visible: true,
  },
  moreMenu: {
    label: 'More',
    menuTools: {
      items: [
        {
          href: '#url',
          'data-tool-id': 1,
          'data-tool-launch-type': null,
          class: null,
          icon: null,
          title: 'External Tool',
        },
      ],
      visible: true,
    },
    exportCourseContent: {
      label: 'Export Course Content',
      url: '/courses/1/modules/export',
      visible: true,
    },
  },
  lastExport: {
    label: 'Last Export:',
    url: '/courses/1/modules/last_export',
    date: '2024-01-01 00:00:00',
    visible: true,
  },
}

describe('ContextModulesHeader', () => {
  afterEach(() => {
    document.body.innerHTML = ''
  })

  describe('basic rendering', () => {
    it('renders the title', () => {
      const {getByRole} = render(<ContextModulesHeader {...defaultProps} />)
      expect(getByRole('heading', {level: 1, name: defaultProps.title})).toBeInTheDocument()
    })

    it('"Publish All" is visible', () => {
      const {getByText} = render(<ContextModulesHeader {...defaultProps} />)
      expect(getByText('Publish All')).toBeInTheDocument()
    })

    it('"Publish All" is disabled', () => {
      global.innerWidth = 500
      global.dispatchEvent(new Event('resize'))

      defaultProps.publishMenu.disabled = true
      const {container} = render(<ContextModulesHeader {...defaultProps} />)
      expect(
        container.querySelector('.context-modules-header-publish-menu-responsive button')
      ).toBeDisabled()
    })

    it('"Publish All" is not visible', () => {
      defaultProps.publishMenu.visible = false
      const {getByText} = render(<ContextModulesHeader {...defaultProps} />)
      expect(() => getByText('Publish All')).toThrow(/Unable to find an element/)
    })

    it('"View Progress" is visible', () => {
      const {getByText} = render(<ContextModulesHeader {...defaultProps} />)
      expect(getByText(defaultProps.viewProgress.label)).toBeInTheDocument()
    })

    it('"View Progress" is not visible', () => {
      defaultProps.viewProgress.visible = false
      const {getByText} = render(<ContextModulesHeader {...defaultProps} />)
      expect(() => getByText(defaultProps.viewProgress.label)).toThrow(/Unable to find an element/)
    })

    it('"Expand / Collapse All" is visible', () => {
      const {getByText} = render(<ContextModulesHeader {...defaultProps} />)
      expect(getByText('Expand All')).toBeInTheDocument()
    })

    it('"Add Module" is visible', () => {
      const {getByText} = render(<ContextModulesHeader {...defaultProps} />)
      expect(getByText(defaultProps.addModule.label)).toBeInTheDocument()
    })

    it('"Add Module" is not visible', () => {
      defaultProps.addModule.visible = false
      const {getByText} = render(<ContextModulesHeader {...defaultProps} />)
      expect(() => getByText(defaultProps.addModule.label)).toThrow(/Unable to find an element/)
    })

    it('"Last Export" is visible', () => {
      const {getByText} = render(<ContextModulesHeader {...defaultProps} />)
      expect(
        getByText(`${defaultProps.lastExport.label} ${defaultProps.lastExport.date}`)
      ).toBeInTheDocument()
    })

    it('"Last Export" is not visible', () => {
      defaultProps.lastExport.visible = false
      const {getByText} = render(<ContextModulesHeader {...defaultProps} />)
      expect(() =>
        getByText(`${defaultProps.lastExport.label} ${defaultProps.lastExport.date}`)
      ).toThrow(/Unable to find an element/)
    })

    it('"More Menu" is visible', () => {
      const {getByRole} = render(<ContextModulesHeader {...defaultProps} />)
      expect(getByRole('button', {name: 'More'})).toBeInTheDocument()
    })

    it('"Export Course Content" is visible inside "More Menu"', () => {
      const {getByRole, getByText} = render(<ContextModulesHeader {...defaultProps} />)
      const button = getByRole('button', {name: 'More'})

      fireEvent.click(button)

      expect(getByText(defaultProps.moreMenu.exportCourseContent.label)).toBeInTheDocument()
    })

    it('"Export Course Content" is not visible inside "More Menu"', () => {
      defaultProps.moreMenu.exportCourseContent.visible = false
      defaultProps.moreMenu.menuTools.visible = true
      const {getByRole, getByText} = render(<ContextModulesHeader {...defaultProps} />)
      const button = getByRole('button', {name: 'More'})

      fireEvent.click(button)

      expect(() => getByText(defaultProps.moreMenu.exportCourseContent.label)).toThrow(
        /Unable to find an element/
      )
    })

    it('"Tools menu" is visible inside "More Menu"', () => {
      const {getByRole, getByText} = render(<ContextModulesHeader {...defaultProps} />)
      const button = getByRole('button', {name: 'More'})

      fireEvent.click(button)

      expect(getByText(defaultProps.moreMenu.menuTools.items[0].title)).toBeInTheDocument()
    })

    it('"Export Course Content" is visible outside "More Menu"', () => {
      defaultProps.moreMenu.exportCourseContent.visible = true
      defaultProps.moreMenu.menuTools.visible = false
      const {getByText} = render(<ContextModulesHeader {...defaultProps} />)
      expect(getByText(defaultProps.moreMenu.exportCourseContent.label)).toBeInTheDocument()
    })

    it('"More Menu" is not visible', () => {
      defaultProps.moreMenu.exportCourseContent.visible = false
      defaultProps.moreMenu.menuTools.visible = false
      const {getByRole} = render(<ContextModulesHeader {...defaultProps} />)
      expect(() => getByRole('button', {name: 'More'})).toThrow(
        /Unable to find an accessible element/
      )
    })
  })
})
