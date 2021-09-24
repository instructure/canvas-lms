# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require 'spec_helper'

describe CanvasQuizStatistics::Analyzers do
  Analyzers = CanvasQuizStatistics::Analyzers

  describe '[]' do
    it 'should locate an analyzer' do
      expect(subject['essay_question']).to eq(Analyzers::Essay)
    end

    it 'should return the generic analyzer for questions of unsupported types' do
      expect(subject['text_only_question']).to eq(Analyzers::Base)
    end
  end
end
