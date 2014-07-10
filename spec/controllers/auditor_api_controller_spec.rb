#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AuditorApiController do
  class AuditsController < AuditorApiController
    def check_configured
      super
    end

    def query_options
      super
    end
  end

  let(:audits_controller) { AuditsController.new }

  context 'check_configured' do
    it 'should return not_found if database is not configured' do
      Canvas::Cassandra::DatabaseBuilder.stubs(:configured?).returns(false)
      audits_controller.expects(:not_found).once
      audits_controller.check_configured

      Canvas::Cassandra::DatabaseBuilder.stubs(:configured?).returns(true)
      audits_controller.check_configured.should be_nil
    end
  end

  context 'query_options' do
    it 'should return hash of audit api parameters' do
      start_time = 5.hours.ago.change(:usec => 0)
      end_time = start_time + 2.hour

      # No params
      audits_controller.stubs(:params).returns({})
      audits_controller.query_options.should == {}

      # Unrelated params
      params = { course_id: 42 }
      audits_controller.stubs(:params).returns(params)
      audits_controller.query_options.should == {}

      # Start time
      params = { start_time: start_time.iso8601 }
      audits_controller.stubs(:params).returns(params)
      audits_controller.query_options.should == { oldest: start_time }

      # End time
      params = { end_time: end_time.iso8601 }
      audits_controller.stubs(:params).returns(params)
      audits_controller.query_options.should == { newest: end_time }

      # Start and end times
      params = {
        start_time: start_time.iso8601,
        end_time: end_time.iso8601
      }
      audits_controller.stubs(:params).returns(params)
      audits_controller.query_options.should == {
        oldest: start_time,
        newest: end_time
      }
    end
  end
end
