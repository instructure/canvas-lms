require_relative '../rails_helper'

RSpec.describe DiscussionEntry do
  include_context "stubbed_network"

  describe '#set_unread_status' do
    let(:course) { course_with_teacher }
    let(:discussion_topic) { discussion_topic_model(context: @course) }
    let(:discussion_entry) { DiscussionEntry.create(discussion_topic: discussion_topic) }

    let(:endpoint) do
      "endpoint/teachers/#{ENV['CANVAS_DOMAIN']}:#{@teacher.id}/topics/#{discussion_topic.id}"
    end

    let(:headers) { { :"x-api-key" => 'key' } }

    before do
      @global_env = {
        TOPIC_MICROSERVICE_ENDPOINT: 'endpoint',
        TOPIC_MICROSERVICE_API_KEY: 'key',
        CANVAS_DOMAIN: 'test'
      }

      allow(HTTParty).to receive(:post)
      allow(HTTParty).to receive(:delete)
      allow(SettingsService).to receive(:get_settings).and_return('show_unread_discussions' => true)
    end

    context 'when the entry has not been read' do
      it 'posts to the endpoint on save' do
        with_modified_env @global_env do
          discussion_entry.change_read_state('unread', @teacher)

          expect(HTTParty).to receive(:post).with(endpoint, headers: headers)

          discussion_entry.save
        end
      end
    end

    context 'when the entry has been read' do
      it 'delete to the endpoint on save' do
        with_modified_env @global_env do
          discussion_entry.change_read_state('read', @teacher)
          expect(HTTParty).to receive(:delete).with(endpoint, headers: headers)

          discussion_entry.save
        end
      end
    end

    context 'when the configuration is missing' do
      it 'wont post to the service' do
        local_env = {
          TOPIC_MICROSERVICE_ENDPOINT: nil,
          TOPIC_MICROSERVICE_API_KEY: nil
        }

        with_modified_env local_env do
          expect(HTTParty).to_not receive(:delete)
          expect(HTTParty).to_not receive(:post)

          discussion_entry.save
        end
      end
    end

    context 'when unread discussion feature flag is off' do
      it 'wont post to the service' do
        allow(SettingsService).to receive(:get_settings).and_return('show_unread_discussions' => false)

        expect(HTTParty).to_not receive(:delete)
        expect(HTTParty).to_not receive(:post)

        discussion_entry.save
      end
    end
  end
end
