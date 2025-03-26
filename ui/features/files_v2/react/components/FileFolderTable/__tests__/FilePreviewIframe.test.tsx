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

import React from 'react';
import { render } from '@testing-library/react';
import { file } from './fixtures'
import '@testing-library/jest-dom';
import FilePreviewIframe from '../FilePreviewIframe';

describe('FilePreviewIframe', () => {
  it('renders with correct sandbox attributes when mime_class is html', () => {
    const item = {
      ...file,
      mime_class: 'html',
      preview_url: 'https://example.com',
      display_name: 'test.html',
    };

    const { getByTitle } = render(<FilePreviewIframe item={item} />);
    const iframe = getByTitle('Preview for file: test.html');

    expect(iframe).toHaveAttribute('sandbox', 'allow-same-origin');
    expect(iframe).toHaveAttribute('src', 'https://example.com');
    expect(iframe).toHaveStyle('background-color: #F2F4F4');
    expect(iframe).toHaveStyle('height: 100%');
    expect(iframe).toHaveStyle('width: 100%');
  });

  it('renders with correct sandbox attributes when mime_class is not html', () => {
    const item = {
      ...file,
      mime_class: 'pdf',
      preview_url: 'https://example.com',
      display_name: 'test.pdf',
    };

    const { getByTitle } = render(<FilePreviewIframe item={item} />);
    const iframe = getByTitle('Preview for file: test.pdf');

    expect(iframe).toHaveAttribute('sandbox', 'allow-scripts allow-same-origin');
    expect(iframe).toHaveAttribute('src', 'https://example.com');
    expect(iframe).not.toHaveStyle('background-color: #F2F4F4');
    expect(iframe).toHaveStyle('height: 100%');
    expect(iframe).toHaveStyle('width: 100%');
  });
});
