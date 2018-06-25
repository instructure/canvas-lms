#
# Copyright (C) 2018 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Lti::RSAKeyPair do
  describe "initialize" do
    it 'generates a public key of default size 256' do
      keys = Lti::RSAKeyPair.new
      expect(/\d+/.match(keys.public_key.to_text())[0]).to eq "256"
    end

    it 'generates a private key of default size 256' do
      keys = Lti::RSAKeyPair.new
      expect(/\d+/.match(keys.private_key.to_text())[0]).to eq "256"
    end

    it 'generates a public key with specified size' do
      keys = Lti::RSAKeyPair.new key_size: 2048
      expect(/\d+/.match(keys.public_key.to_text())[0]).to eq "2048"
    end

    it 'generates a private key with specified size' do
      keys = Lti::RSAKeyPair.new key_size: 2048
      expect(/\d+/.match(keys.private_key.to_text())[0]).to eq "2048"
    end
  end
end
