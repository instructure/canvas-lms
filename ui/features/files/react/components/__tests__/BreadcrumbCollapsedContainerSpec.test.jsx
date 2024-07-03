/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import { render, cleanup, fireEvent } from '@testing-library/react'
import BreadcrumbCollapsedContainer from '../BreadcrumbCollapsedContainer'
import Folder from '@canvas/files/backbone/models/Folder'
import stubRouterContext from '../../../../../shared/test-utils/stubRouterContext'

describe('BreadcrumbsCollapsedContainer', () => {
  let Component;

  beforeEach(() => {
    const folder = new Folder({ name: 'Test Folder', urlPath: 'test_url', url: 'stupid' });
    folder.url = () => 'stupid';

    const props = { foldersToContain: [folder] };
    Component = stubRouterContext(BreadcrumbCollapsedContainer, props);
  });

  afterEach(cleanup);

  it('opens breadcrumbs on mouse enter', () => {
    const { getByText } = render(<Component />);
    const ellipsis = getByText('…').closest('li');
    fireEvent.mouseEnter(ellipsis);
    expect(ellipsis.querySelector('.open')).toBeTruthy();
  });

  it('opens breadcrumbs on focus', () => {
    const { getByText } = render(<Component />);
    const ellipsis = getByText('…').closest('li');
    fireEvent.focus(ellipsis);
    expect(ellipsis.querySelector('.open')).toBeTruthy();
  });

  it('closes breadcrumbs on mouse leave', () => {
    jest.useFakeTimers();
    const { getByText } = render(<Component />);
    const ellipsis = getByText('…').closest('li');
    fireEvent.mouseLeave(ellipsis);
    jest.advanceTimersByTime(200);
    expect(ellipsis.querySelector('.closed')).toBeTruthy();
    jest.useRealTimers();
  });

  it('closes breadcrumbs on blur', () => {
    jest.useFakeTimers();
    const { getByText } = render(<Component />);
    const ellipsis = getByText('…').closest('li');
    fireEvent.blur(ellipsis);
    jest.advanceTimersByTime(200);
    expect(ellipsis.querySelector('.closed')).toBeTruthy();
    jest.useRealTimers();
  });
});
