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

RSpec.shared_context "services JWT wrapper" do
  def build_wrapped_token(user_id, real_user_id: nil, encoding_secret: fake_signing_secret)
    payload = { sub: user_id }
    payload[:masq_sub] = real_user_id if real_user_id
    crypted_token = CanvasSecurity::ServicesJwt.generate(payload, false, symmetric: true)
    payload = {
      iss: "some other service",
      user_token: crypted_token
    }
    wrapper_token = CanvasSecurity.create_jwt(payload, nil, encoding_secret)
    # because it will come over base64 encoded from any other service
    CanvasSecurity.base64_encode(wrapper_token)
  end
end

RSpec.shared_context "JWT setup" do
  include_context "services JWT wrapper"

  let(:fake_encryption_secret) { "jkl;jkl;jkl;jkl;jkl;jkl;jkl;jkl;" }
  let(:fake_signing_secret) { "asdfasdfasdfasdfasdfasdfasdfasdf" }
  let(:fallback_proxy) do
    DynamicSettings::FallbackProxy.new({
                                         CanvasSecurity::KeyStorage::PAST => CanvasSecurity::KeyStorage.new_key,
                                         CanvasSecurity::KeyStorage::PRESENT => CanvasSecurity::KeyStorage.new_key,
                                         CanvasSecurity::KeyStorage::FUTURE => CanvasSecurity::KeyStorage.new_key
                                       })
  end

  before do
    allow(Rails).to receive(:application).and_return(instance_double("Rails::Application", credentials: {})) unless Rails.application.present?

    allow(Rails.application.credentials).to receive(:dig).and_call_original
    allow(Rails.application.credentials).to receive(:dig).with(:canvas_security, :encryption_secret).and_return(fake_encryption_secret)
    allow(Rails.application.credentials).to receive(:dig).with(:canvas_security, :signing_secret).and_return(fake_signing_secret)

    allow(DynamicSettings).to receive(:kv_proxy).and_return(fallback_proxy)
  end

  after do
    Timecop.return
  end

  around do |example|
    Timecop.freeze(Time.utc(2013, 3, 13, 9, 12), &example)
  end
end

RSpec.shared_context "JWT setup with deprecated secret" do
  include_context "services JWT wrapper"

  let(:fake_encryption_secret) { "qrstuvwxyzqrstuvwxyzqrstuvwxyzqr" }
  let(:fake_signing_secret) { "abcdefghijklmnopabcdefghijklmnop" }
  let(:fake_signing_secret_deprecated) { "nowiknowmyabcsnexttimewontyou..." }

  before do
    allow(Rails).to receive(:application).and_return(instance_double("Rails::Application", credentials: {})) unless Rails.application.present?

    allow(Rails.application.credentials).to receive(:dig).and_call_original
    allow(Rails.application.credentials).to receive(:dig).with(:canvas_security, :encryption_secret).and_return(fake_encryption_secret)
    allow(Rails.application.credentials).to receive(:dig).with(:canvas_security, :signing_secret).and_return(fake_signing_secret)
    allow(Rails.application.credentials).to receive(:dig).with(:canvas_security, :signing_secret_deprecated).and_return(fake_signing_secret_deprecated)
  end

  after do
    Timecop.return
  end

  around do |example|
    Timecop.freeze(Time.utc(2021, 1, 11, 13, 21), &example)
  end
end
