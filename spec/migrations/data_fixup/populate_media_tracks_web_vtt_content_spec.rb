# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require_relative '../../spec_helper'

RSpec.describe DataFixup::PopulateMediaTracksWebVttContent do
  def webvtt_content
    <<-HEREDOC
      WEBVTT

      00:01.000 --> 00:04.000
      Never drink liquid nitrogen.

      00:05.000 --> 00:09.000
      - It will perforate your stomach.
      - You could die.
        end
    HEREDOC
  end

  def srt_content
    <<-HEREDOC
      1
      00:00:01,600 --> 00:00:04,200
      English (US)

      2
      00:00:05,900 --> 00:00:07,999
      This is a subtitle in American English

      3
      00:00:10,000 --> 00:00:14,000
      Adding subtitles is very easy to do
    HEREDOC
  end

  it 'converts content of type srt to web_vtt' do
    mo = MediaObject.create!(media_id: 'm1234')
    mt = MediaTrack.create!(content: srt_content, media_object: mo)
    DataFixup::PopulateMediaTracksWebVttContent.run
    expect(mt.read_attribute(:webvtt_content)).not_to be_nil
    expect(mt.read_attribute(:webvtt_content)).to include('WEBVTT')
  end

  it 'will not convert content if already webvtt' do
    mo = MediaObject.create!(media_id: 'm1234')
    mt = MediaTrack.create!(content: webvtt_content, media_object: mo)
    DataFixup::PopulateMediaTracksWebVttContent.run
    expect(mt.read_attribute(:webvtt_content)).to be_nil
    expect(mt.read_attribute(:content)).to include('WEBVTT')
  end

  it 'will attempt to convert bad formatted srt' do
    mo = MediaObject.create!(media_id: 'm1234')
    mt = MediaTrack.create!(content: '123$%blah#badmanbad', media_object: mo)
    DataFixup::PopulateMediaTracksWebVttContent.run
    expect(mt.read_attribute(:webvtt_content)).not_to be_nil
    expect(mt.read_attribute(:webvtt_content)).to include('WEBVTT')
  end
end
