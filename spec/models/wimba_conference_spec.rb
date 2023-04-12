# frozen_string_literal: true

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

require_relative("web_conference_spec_helper")

describe WimbaConference do
  include_examples "WebConference"

  # implements this WebConference option:
  it { is_expected.to respond_to :admin_settings_url }

  before(:all) do
    WimbaConference.class_eval do
      # set up a simple double that mimics basic API functionality
      def send_request(action, opts = {})
        @mocked_users ||= { added: [], admins: [], joined: [] }
        extra = ""
        if action == "Init"
          @auth_cookie = "authcookie=secret"
        else
          return nil unless init_session
          return nil unless @auth_cookie == "authcookie=secret"

          case action
          when "modifyUser"
            return nil unless @mocked_users[:added].include?(opts["target"])
          when "createUser"
            @mocked_users[:added] << opts["target"]
          when "createRole"
            @mocked_users[:admins] << opts["user_id"] if opts["role_id"] == "Instructor"
          when "getAuthToken"
            return nil unless @mocked_users[:added].include?(opts["target"])
            return nil if @mocked_users[:joined].empty? && !@mocked_users[:admins].include?(opts["target"])

            @mocked_users[:joined] << opts["target"]
            extra = "\nauthToken=s3kr1tfor#{opts["target"]}\nuser_id=#{opts["target"]}\n=END RECORD"
          when "statusClass"
            extra = "\nnum_users=#{@mocked_users[:joined].size}\nroomlock=\n=END RECORD"
          when "listClass"
            extra = "\nclass_id=abc123\nlongname=ABC 123\n=END RECORD\nlongname=DEF 456\nclass_id=def456\n=END RECORD"
          end
        end
        "100 OK#{extra}"
      end
    end
  end

  before :once do
    user_model
  end

  before do
    allow(WebConference).to receive(:plugins).and_return([web_conference_plugin_mock("wimba", { domain: "wimba.test" })])
    email = "email@email.com"
    allow(@user).to receive(:email).and_return(email)
  end

  it "retrieves a config hash correctly" do
    conference = WimbaConference.new
    config = conference.config
    expect(config).not_to be_nil
    expect(config[:conference_type]).to eql("Wimba")
    expect(config[:class_name]).to eql("WimbaConference")
  end

  it "confirms valid config" do
    expect(WimbaConference.new.valid_config?).to be_truthy
    expect(WimbaConference.new(conference_type: "Wimba").valid_config?).to be_truthy
  end

  it "is active if an admin has joined" do
    conference = WimbaConference.create!(title: "my conference", user: @user, context: course_factory)
    # this makes it active
    conference.initiate_conference
    expect(conference.admin_join_url(@user)).not_to be_nil

    expect(conference.conference_status).to be(:active)
    expect(conference.participant_join_url(@user)).not_to be_nil
  end

  it "is closed if it has not been initiated" do
    conference = WimbaConference.create!(title: "my conference", user: @user, context: course_factory)
    expect(conference.conference_status).to be(:closed)
    expect(conference.participant_join_url(@user)).to be_nil
  end

  it "is closed if no admins have joined" do
    conference = WimbaConference.create!(title: "my conference", user: @user, context: course_factory)
    conference.initiate_conference
    expect(conference.conference_status).to be(:closed)
    expect(conference.participant_join_url(@user)).to be_nil
  end

  it "generates join urls correctly" do
    conference = WimbaConference.create!(title: "my conference", user: @user, context: course_factory)
    conference.initiate_conference
    # join urls for admins and participants look the same (though token will vary by user), since
    # someone's admin/participant-ness is negotiated beforehand through api calls and isn't
    # reflected in the token/url
    join_url = "http://wimba.test/launcher.cgi.pl?hzA=s3kr1tfor#{conference.wimba_id(@user.uuid)}&room=#{conference.wimba_id}"
    expect(conference.admin_join_url(@user)).to eql(join_url)
    expect(conference.participant_join_url(@user)).to eql(join_url)
  end

  it "returns archive urls correctly" do
    conference = WimbaConference.create!(title: "my conference", user: @user, context: course_factory)
    conference.initiate_conference
    conference.admin_join_url(@user)
    conference.started_at = 1.hour.ago
    conference.ended_at = 1.hour.ago
    conference.save
    urls = conference.external_url_for("archive", @user)
    expect(urls).to eql [{ id: "abc123", name: "ABC 123" }, { id: "def456", name: "DEF 456" }]
  end

  it "does not return archive urls if the conference hasn't started" do
    conference = WimbaConference.create!(title: "my conference", user: @user, duration: 120, context: course_factory)
    expect(conference.external_url_for("archive", @user)).to be_empty
  end
end
