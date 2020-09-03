#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe PseudonymSession do
  before(:each) do
    fake_controller_cls = Class.new do
      attr_reader :request
      def initialize
        request_cls = Class.new do
          def ip
            '127.0.0.1'
          end
        end
        @request = request_cls.new
      end

      def last_request_update_allowed?
        true
      end

      def params
        {}
      end

      def session
        {}
      end

      def cookies
        {}
      end
    end
    Authlogic::Session::Base.controller = fake_controller_cls.new
  end

  after(:each) do
    Authlogic::Session::Base.controller = nil
  end
  describe "save_record" do
    it "will not overwrite the last_request_at within the configured window" do
      pseud = pseudonym_model
      expected_timestamp = Time.now.utc
      pseud.last_request_at = 1.hour.ago
      pseud.save!
      pseud.last_request_at = expected_timestamp
      sess = PseudonymSession.new
      sess.record = pseud
      sess.save_record
      expect(pseud.reload.last_request_at).to eq(expected_timestamp)
      pseud.last_request_at = 1.second.from_now.utc
      sess.save_record
      expect(pseud.reload.last_request_at).to eq(expected_timestamp)
    end

    it "will update when other values also change" do
      pseud = pseudonym_model
      pseud.last_request_at = 1.hour.ago
      pseud.save!
      expected_timestamp = Time.now.utc
      pseud.last_request_at = expected_timestamp
      sess = PseudonymSession.new
      sess.record = pseud
      sess.save_record
      expect(pseud.reload.last_request_at).to eq(expected_timestamp)
      pseud.last_request_at = 1.second.from_now.utc
      pseud.unique_id = 'some new value'
      sess.save_record
      expect(pseud.reload.last_request_at > expected_timestamp).to be_truthy
    end
  end
end