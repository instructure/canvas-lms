# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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
#
require 'spec_helper'

describe AdheresToPolicy::Configuration do
  let(:config) { AdheresToPolicy::Configuration.new }

  describe '#blacklist' do
    it 'must default to an empty array' do
      expect(config.blacklist).to eq []
    end

    it 'must return the literal value set' do
      config.blacklist = %w{foo bar}
      expect(config.blacklist).to eq %w{foo bar}
    end

    it 'must evaluate the supplied block and return the result' do
      config.blacklist = -> {
        %w{baz qux}
      }

      expect(config.blacklist).to eq %w{baz qux}
    end
  end

  describe '#cache_related_permissions' do
    it 'must default to true' do
      expect(config.cache_related_permissions).to be_truthy
    end

    it 'must return the literal value set' do
      config.cache_related_permissions = false
      expect(config.cache_related_permissions).to be_falsy
    end

    it 'must evaluate the supplied block and return the result' do
      config.cache_related_permissions = -> { false }
      expect(config.cache_related_permissions).to be_falsy
    end
  end
end
