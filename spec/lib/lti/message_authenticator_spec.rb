#
# Copyright (C) 2011 - 2016 Instructure, Inc.
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
require_dependency "lti/message_authenticator"

module Lti
  describe MessageAuthenticator do

    let(:launch_url) {'http://test.com/test'}
    let(:course) {Course.create!}
    let!(:tool) do
      course.context_external_tools.create!(
        {
          name: 'test tool',
          domain:'test.com',
          consumer_key: 'key',
          shared_secret: 'secret'
        }
      )
    end

    let(:message) do
      m = IMS::LTI::Models::Messages::ContentItemSelection.new(
        {
          lti_message_type: 'ContentItemSelection',
          lti_version: 'LTI-1p0',
          content_items: File.read(File.join(Rails.root, 'spec', 'fixtures', 'lti', 'content_items.json')),
          data: Canvas::Security.create_jwt({content_item_id: "3"}),
          lti_msg: '',
          lti_log: '',
          lti_errormsg: '',
          lti_errorlog: ''
        }
      )
      m.launch_url = launch_url
      m.oauth_consumer_key = tool.consumer_key
      m
    end
    subject{described_class.new(launch_url, message.signed_post_params(tool.shared_secret))}

    it 'creates a message from the signed_params' do
      expect(subject.message.oauth_consumer_key).to eq tool.consumer_key
    end

    describe "#valid?" do
      it 'validates a message' do
        expect(subject.valid?).to be true
      end

      context 'content-item unique json serialization' do
        let(:launch_url) {"http://test.com/test"}
        let(:secret) {'secret'}
        let(:signed_params) {
          {
            :oauth_callback=>"about:blank",
            :oauth_consumer_key=>"key",
            :oauth_nonce=>"89fc77055d2a051de296fc5d99987a20",
            :oauth_signature_method=>"HMAC-SHA1",
            :oauth_timestamp=>"1467842103",
            :oauth_version=>"1.0",
            :oauth_signature=>"TL8PLA/V43D21+JkGg8i9Cj+Dqg=",
            "lti_message_type"=>"ContentItemSelection",
            "lti_version"=>"LTI-1p0",
            "content_items"=>"{\"@graph\":[{\"windowTarget\":\"\",\"text\":\"Arch Linux\",\"title\":\"Its your "+
                             "computer\",\"url\":\"http://lti-tool-provider-example.dev/messages/blti\""+
                             ",\"thumbnail\":{\"height\":128,\"width\":128,\"@id\""+
                             ":\"http://www.runeaudio.com/assets/img/banner-archlinux.png\"}"+
                             ",\"placementAdvice\":{\"displayHeight\":600,\"displayWidth\":800"+
                             ",\"presentationDocumentTarget\":\"iframe\"},\"mediaType\""+
                             ":\"application/vnd.ims.lti.v1.ltilink\",\"@type\":\"LtiLinkItem\",\"@id\""+
                             ":\"http://lti-tool-provider-example.dev/messages/blti\"}],\"@context\""+
                             ":\"http://purl.imsglobal.org/ctx/lti/v1/ContentItem\"}",
            "lti_msg"=>"",
            "lti_log"=>"",
            "lti_errormsg"=>"",
            "lti_errorlog"=>""
          }
        }

        it "validates the message" do
          message_authenticator = MessageAuthenticator.new(launch_url, signed_params)
          Timecop.freeze(Time.at(signed_params[:oauth_timestamp].to_i)) do
            expect(message_authenticator.valid?).to eq true
          end
        end
      end

      it "returns the same value if called multiple times" do
        enable_cache do
          expect(2.times.map { |_| subject.valid? }).to eq [true, true]
        end
      end

      it 'rejects an invalid secret' do
        validator = described_class.new(launch_url, message.signed_post_params('invalid'))
        expect(validator.valid?).to be false
      end

      it 'rejects a used nonce' do
        enable_cache do
          signed_params = message.signed_post_params(tool.shared_secret)
          validator1 = described_class.new(launch_url, signed_params)
          validator2 = described_class.new(launch_url, signed_params)
          expect(validator1.valid?).to be true
          expect(validator2.valid?).to be false
        end
      end

      it 'rejects a message older than the NONCE_EXPIRATION' do
        enable_cache do
          validator = nil
          Timecop.freeze((described_class::NONCE_EXPIRATION + 1.minute).ago) do
            validator = described_class.new(launch_url, message.signed_post_params(tool.shared_secret))
          end
          expect(validator.valid?).to be false
        end
      end

      it "doesn't store the nonce if the signature is invalid" do
        enable_cache do
          validator = described_class.new(launch_url, message.signed_post_params('invalid'))
          expect(validator.valid?).to be false
          expect(Rails.cache.exist?(validator.send(:cache_key))).to be_falsey
        end
      end

    end
  end



end
