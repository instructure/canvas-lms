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
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event'
import FilePreviewTray from '../FilePreviewTray';
import { MediaInfo } from '@canvas/canvas-studio-player/react/types';
import type {File} from "../../../../../interfaces/File.ts"

jest.mock('../CommonFileInfo', () => jest.fn(() => <div data-testid="common-file-info" />));
jest.mock('../MediaFileInfo', () => jest.fn(() => <div data-testid="media-file-info" />));

describe('FilePreviewTray', () => {
  const mockOnDismiss = jest.fn();
  const mockItem = {
    id: '1',
    name: 'Sample File',
    type: 'document',
  } as unknown as File;

  const mockMediaInfo = {
    duration: 120,
    format: 'mp4',
  } as unknown as MediaInfo;

  it('renders with the appropriate children components', () => {
    render(<FilePreviewTray onDismiss={mockOnDismiss} item={mockItem} mediaInfo={mockMediaInfo} />);
    expect(screen.getByTestId('tray-close-button')).toBeInTheDocument();
    expect(screen.getByTestId('common-file-info')).toBeInTheDocument();
    expect(screen.getByTestId('media-file-info')).toBeInTheDocument();
  });

  it('calls onDismiss when close button is clicked', async () => {
    const user = userEvent.setup()
    render(<FilePreviewTray onDismiss={mockOnDismiss} item={mockItem} mediaInfo={mockMediaInfo}/>);
    await user.click(screen.getByTestId('tray-close-button').querySelector('button') as HTMLButtonElement);
    expect(mockOnDismiss).toHaveBeenCalledTimes(1);
  });
});
