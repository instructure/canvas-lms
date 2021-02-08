# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

describe UuidHelper do
  describe ".valid_format?" do
    it { expect(described_class.valid_format?(nil)).to be false }

    it { expect(described_class.valid_format?('')).to be false }

    it { expect(described_class.valid_format?('foo')).to be false }

    it { expect(described_class.valid_format?('09c1686-cab5-4df-b13-c77f76f75db')).to be false }

    it { expect(described_class.valid_format?('309c1686-cab5-44df-8b13-fc77f76f75db')).to be true }
  end
end
