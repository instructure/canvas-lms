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
import MediaFileInfo from '../MediaFileInfo';
import { MediaInfo, MediaTrack } from '@canvas/canvas-studio-player/react/types';

describe('MediaFileInfo', () => {
  it('renders video options heading when mediaInfo is provided', () => {
    const mockMediaInfo: MediaInfo = {
      can_add_captions: true,
      media_tracks: [],
    } as unknown as MediaInfo;

    render(<MediaFileInfo mediaInfo={mockMediaInfo} />);
    expect(screen.getByText('Video Options')).toBeInTheDocument();
    expect(screen.getByText('None')).toBeInTheDocument();
  });

  it('renders closed captions section when media tracks exist', () => {
    const mockMediaTracks: MediaTrack[] = [
      { id: '1', locale: 'en' },
      { id: '2', locale: 'es' }
    ] as unknown as MediaTrack[];

    const mockMediaInfo: MediaInfo = {
      can_add_captions: true,
      media_tracks: mockMediaTracks,
    } as MediaInfo;

    render(<MediaFileInfo mediaInfo={mockMediaInfo} />);
    expect(screen.getByText('Closed Captions/Subtitles')).toBeInTheDocument();
    expect(screen.getByText('English')).toBeInTheDocument();
    expect(screen.getByText('Spanish')).toBeInTheDocument();
  });

  it('renders nothing when mediaInfo is null or captions are not allowed', () => {
    const { container } = render(<MediaFileInfo mediaInfo={{} as MediaInfo} />);
    expect(container.firstChild).toBeNull();

    const mockMediaInfo: MediaInfo = {
      can_add_captions: false,
      media_tracks: [{ id: '1', locale: 'en' }] as MediaTrack[],
    } as MediaInfo;

    const { container: container2 } = render(<MediaFileInfo mediaInfo={mockMediaInfo} />);
    expect(container2.firstChild).toBeNull();
  });
});
