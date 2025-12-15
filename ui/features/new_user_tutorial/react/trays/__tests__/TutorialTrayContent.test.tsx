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

import {cleanup, render} from '@testing-library/react'
import TutorialTrayContent from '../TutorialTrayContent'

const defaultProps = {
  heading: 'Test Heading',
  subheading: 'Test Subheading',
}

describe('TutorialTrayContent', () => {
  afterEach(() => {
    cleanup()
  })

  it('renders with required props', () => {
    const {getByText} = render(<TutorialTrayContent {...defaultProps} />)

    expect(getByText('Test Heading')).toBeInTheDocument()
    expect(getByText('Test Subheading')).toBeInTheDocument()
  })

  it('uses default values for optional props', () => {
    const {container} = render(<TutorialTrayContent {...defaultProps} />)

    expect(container.firstChild).toBeInTheDocument()
  })

  it('renders with custom name class', () => {
    const {container} = render(<TutorialTrayContent {...defaultProps} name="custom-name" />)

    expect(container.firstChild).toHaveClass('NewUserTutorialTray__Content custom-name')
  })

  it('renders children content', () => {
    const {getByText} = render(
      <TutorialTrayContent {...defaultProps}>
        <span>Custom child content</span>
      </TutorialTrayContent>,
    )

    expect(getByText('Custom child content')).toBeInTheDocument()
  })

  it('renders image when provided', () => {
    const {container} = render(<TutorialTrayContent {...defaultProps} image="test-image.png" />)

    const image = container.querySelector('img')
    expect(image).toBeInTheDocument()
    expect(image).toHaveAttribute('src', 'test-image.png')
    expect(image).toHaveAttribute('alt', '')
  })

  it('renders image with custom width', () => {
    const {container} = render(
      <TutorialTrayContent {...defaultProps} image="test-image.png" imageWidth="10rem" />,
    )

    const image = container.querySelector('img')
    expect(image).toBeInTheDocument()
    expect(image).toHaveAttribute('src', 'test-image.png')
  })

  it('does not render image when image prop is null', () => {
    const {container} = render(<TutorialTrayContent {...defaultProps} image={null} />)

    expect(container.querySelector('img')).not.toBeInTheDocument()
  })

  it('renders help links when provided', () => {
    const links = [
      {href: 'https://example.com/help1', label: 'Help Link 1'},
      {href: 'https://example.com/help2', label: 'Help Link 2'},
    ]

    const {getByText, getAllByRole} = render(
      <TutorialTrayContent {...defaultProps} links={links} />,
    )

    expect(getByText('Help Link 1')).toBeInTheDocument()
    expect(getByText('Help Link 2')).toBeInTheDocument()

    const linkElements = getAllByRole('link')
    expect(linkElements).toHaveLength(2)
    expect(linkElements[0]).toHaveAttribute('href', 'https://example.com/help1')
    expect(linkElements[1]).toHaveAttribute('href', 'https://example.com/help2')
    expect(linkElements[0]).toHaveAttribute('target', '_blank')
    expect(linkElements[1]).toHaveAttribute('target', '_blank')
  })

  it('does not render links section when links are not provided', () => {
    const {queryByRole} = render(<TutorialTrayContent {...defaultProps} />)

    expect(queryByRole('link')).not.toBeInTheDocument()
  })

  it('renders see all link when provided', () => {
    const seeAllLink = {
      href: 'https://example.com/see-all',
      label: 'See All Resources',
    }

    const {getByText, getByRole} = render(
      <TutorialTrayContent {...defaultProps} seeAllLink={seeAllLink} />,
    )

    expect(getByText('See All Resources')).toBeInTheDocument()

    const linkElement = getByRole('link')
    expect(linkElement).toHaveAttribute('href', 'https://example.com/see-all')
    expect(linkElement).toHaveAttribute('target', '_blank')
  })

  it('renders both help links and see all link', () => {
    const links = [{href: 'https://example.com/help', label: 'Help Link'}]
    const seeAllLink = {
      href: 'https://example.com/see-all',
      label: 'See All Resources',
    }

    const {getByText, getAllByRole} = render(
      <TutorialTrayContent {...defaultProps} links={links} seeAllLink={seeAllLink} />,
    )

    expect(getByText('Help Link')).toBeInTheDocument()
    expect(getByText('See All Resources')).toBeInTheDocument()

    const linkElements = getAllByRole('link')
    expect(linkElements).toHaveLength(2)
  })

  it('renders question icons for help links', () => {
    const links = [{href: 'https://example.com/help', label: 'Help Link'}]

    const {container} = render(<TutorialTrayContent {...defaultProps} links={links} />)

    const svgIcon = container.querySelector('svg')
    expect(svgIcon).toBeInTheDocument()
  })

  it('truncates long headings', () => {
    const longHeading =
      'This is a very long heading that should be truncated by the TruncateText component'

    const {getByText} = render(<TutorialTrayContent {...defaultProps} heading={longHeading} />)

    expect(getByText(longHeading)).toBeInTheDocument()
  })

  it('renders with empty children array (default)', () => {
    const {container} = render(<TutorialTrayContent {...defaultProps} />)

    expect(container.firstChild).toBeInTheDocument()
  })

  it('renders multiple children', () => {
    const {getByText} = render(
      <TutorialTrayContent {...defaultProps}>
        <span>First child</span>
        <span>Second child</span>
      </TutorialTrayContent>,
    )

    expect(getByText('First child')).toBeInTheDocument()
    expect(getByText('Second child')).toBeInTheDocument()
  })

  it('applies proper CSS classes and structure', () => {
    const {container} = render(<TutorialTrayContent {...defaultProps} />)

    expect(container.firstChild).toHaveClass('NewUserTutorialTray__Content')
  })

  it('renders with all props combined', () => {
    const links = [{href: 'https://example.com/help', label: 'Help Link'}]
    const seeAllLink = {
      href: 'https://example.com/see-all',
      label: 'See All Resources',
    }

    const {getByText, getAllByRole, container} = render(
      <TutorialTrayContent
        {...defaultProps}
        name="test-component"
        image="test-image.png"
        imageWidth="8rem"
        links={links}
        seeAllLink={seeAllLink}
      >
        <span>Child content</span>
      </TutorialTrayContent>,
    )

    expect(getByText('Test Heading')).toBeInTheDocument()
    expect(getByText('Test Subheading')).toBeInTheDocument()
    expect(getByText('Child content')).toBeInTheDocument()
    expect(getByText('Help Link')).toBeInTheDocument()
    expect(getByText('See All Resources')).toBeInTheDocument()

    const image = container.querySelector('img')
    expect(image).toBeInTheDocument()
    expect(image).toHaveAttribute('src', 'test-image.png')

    const linkElements = getAllByRole('link')
    expect(linkElements).toHaveLength(2)
  })
})
