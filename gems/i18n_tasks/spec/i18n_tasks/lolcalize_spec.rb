# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module I18nTasks
  class LolcalizeHarness
    include Lolcalize
  end

  describe 'Lolcalize' do
    describe 'i18n_lolcalize' do
      it 'handles a string' do
        res = LolcalizeHarness.new.i18n_lolcalize('Hello')
        expect(res).to eq('hElLo! LOL!')
      end

      it 'handles a hash' do
        res = LolcalizeHarness.new.i18n_lolcalize({ one: 'Hello', other: 'Hello %{count}' })
        expect(res).to eq({ one: 'hElLo! LOL!', other: 'hElLo! LOL! %{count}' })
      end
    end
  end
end
