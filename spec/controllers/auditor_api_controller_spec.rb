# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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
      allow(Canvas::Cassandra::DatabaseBuilder).to receive(:configured?).and_return(false)
      expect(audits_controller).to receive(:render).with(hash_including(status: :not_found))
      audits_controller.check_configured
    end

    it 'should not block when database is configured' do
      allow(Canvas::Cassandra::DatabaseBuilder).to receive(:configured?).and_return(true)
      expect(audits_controller.check_configured).to be_nil
    end
  end

  context 'query_options' do
    it 'should return hash of audit api parameters' do
      start_time = 5.hours.ago.change(:usec => 0)
      end_time = start_time + 2.hour

      # No params
      allow(audits_controller).to receive(:params).and_return({})
      expect(audits_controller.query_options).to eq({})

      # Unrelated params
      params = { course_id: 42 }
      allow(audits_controller).to receive(:params).and_return(params)
      expect(audits_controller.query_options).to eq({})

      # Start time
      params = { start_time: start_time.iso8601 }
      allow(audits_controller).to receive(:params).and_return(params)
      expect(audits_controller.query_options).to eq({ oldest: start_time })

      # End time
      params = { end_time: end_time.iso8601 }
      allow(audits_controller).to receive(:params).and_return(params)
      expect(audits_controller.query_options).to eq({ newest: end_time })

      # Start and end times
      params = {
        start_time: start_time.iso8601,
        end_time: end_time.iso8601
      }
      allow(audits_controller).to receive(:params).and_return(params)
      expect(audits_controller.query_options).to eq({
        oldest: start_time,
        newest: end_time
      })
    end
  end
end
