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
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe BounceNotificationProcessor do
  before(:once) do
    bounce_queue_log = File.read(File.dirname(__FILE__) + '/../fixtures/bounces.json')
    @all_bounce_messages_json = JSON.parse(bounce_queue_log)
    @soft_bounce_messages_json = @all_bounce_messages_json.select {|m| m['Message'].include?('Transient')}
    @hard_bounce_messages_json = @all_bounce_messages_json.select {|m| m['Message'].include?('Permanent')}
    @bounce_count = @all_bounce_messages_json.count do |notification|
      JSON.parse(notification['Message'])['notificationType'] == 'Bounce'
    end
  end

  def mock_message(json)
    message = double
    allow(message).to receive(:body).and_return(json.to_json)
    message
  end

  describe ".process" do
    it "processes each notification in the queue" do
      bnp = BounceNotificationProcessor.new
      allow(BounceNotificationProcessor).to receive(:config).and_return({
        access_key: 'key',
        secret_access_key: 'secret'
      })
      queue = double
      expectation = receive(:poll)
      @all_bounce_messages_json.each do |m|
        expectation.and_yield(mock_message(m))
      end
      expect(queue).to expectation
      allow(bnp).to receive(:bounce_queue).and_return(queue)
      expect(bnp).to receive(:process_bounce_notification).exactly(@bounce_count).times
      bnp.process
    end

    it "flags addresses with hard bounces" do
      bnp = BounceNotificationProcessor.new
      allow(BounceNotificationProcessor).to receive(:config).and_return({
        access_key: 'key',
        secret_access_key: 'secret'
      })
      queue = double
      expectation = receive(:poll)
      @all_bounce_messages_json.each do |m|
        expectation.and_yield(mock_message(m))
      end
      expect(queue).to expectation
      allow(bnp).to receive(:bounce_queue).and_return(queue)

      expect(CommunicationChannel).to receive(:bounce_for_path).
        with(include(path: 'hard@example.edu',
                     timestamp: '2014-08-22T12:25:46.786Z',
                     permanent_bounce: true,
                     suppression_bounce: false)).
        exactly(4).times
      expect(CommunicationChannel).to receive(:bounce_for_path).
        with(include(path: 'suppressed@example.edu',
                     timestamp: '2014-08-22T12:18:58.044Z',
                     permanent_bounce: true,
                     suppression_bounce: true)).
        exactly(3).times
      expect(CommunicationChannel).to receive(:bounce_for_path).
        with(include(path: 'soft@example.edu',
                     timestamp: '2014-08-22T13:24:31.000Z',
                     permanent_bounce: false,
                     suppression_bounce: false)).
        exactly(:once)

      bnp.process
    end

    it 'pings statsd' do
      bnp = BounceNotificationProcessor.new
      allow(BounceNotificationProcessor).to receive(:config).and_return({
        access_key: 'key',
        secret_access_key: 'secret'
      })
      queue = double
      expectation = receive(:poll)
      @all_bounce_messages_json.each do |m|
        expectation.and_yield(mock_message(m))
      end
      expect(queue).to expectation
      allow(bnp).to receive(:bounce_queue).and_return(queue)
      allow(CommunicationChannel).to receive(:bounce_for_path)

      expect(InstStatsd::Statsd).to receive(:increment).with('bounce_notification_processor.processed.transient').once
      expect(InstStatsd::Statsd).to receive(:increment).with('bounce_notification_processor.processed.no_bounce').twice
      expect(InstStatsd::Statsd).to receive(:increment).with('bounce_notification_processor.processed.suppression').exactly(3).times
      expect(InstStatsd::Statsd).to receive(:increment).with('bounce_notification_processor.processed.permanent').exactly(4).times

      bnp.process
    end
  end
end
