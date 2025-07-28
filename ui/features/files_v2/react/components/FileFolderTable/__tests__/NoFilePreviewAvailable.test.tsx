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
import NoFilePreviewAvailable from '../NoFilePreviewAvailable';

describe('NoFilePreviewAvailable', () => {
  it('renders the "No Preview Available" message', () => {
    const item = {
      ...file,
      display_name: 'example.pdf',
      url: 'https://example.com/example.pdf',
      size: 1024,
    };

    const { getByText, getByTestId } = render(<NoFilePreviewAvailable item={item} />);

    expect(getByText('No Preview Available')).toBeInTheDocument();
    expect(getByTestId('file-display-name')).toBeInTheDocument();
    expect(getByText('1 KB')).toBeInTheDocument();
  });

  it('renders the download button with correct href', () => {
    const item = {
      ...file,
      display_name: 'example.pdf',
      url: 'https://example.com/example.pdf',
      size: 1024,
    };

    const { getByRole } = render(<NoFilePreviewAvailable item={item} />);
    const downloadButton = getByRole('link', { name: 'Download' });

    expect(downloadButton).toBeInTheDocument();
    expect(downloadButton).toHaveAttribute('href', 'https://example.com/example.pdf');
  });

  it('does not display file size if not present in item', () => {
    const item = {
      ...file,
      display_name: 'example.pdf',
      url: 'https://example.com/example.pdf',
    };

    const { queryByText } = render(<NoFilePreviewAvailable item={item} />);

    expect(queryByText('1024 KB')).not.toBeInTheDocument();
  });
});
