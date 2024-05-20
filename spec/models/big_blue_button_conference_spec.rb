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

require_relative("web_conference_spec_helper")

describe BigBlueButtonConference do
  include_examples "WebConference"

  context "big_blue_button" do
    before do
      allow(WebConference).to receive(:plugins).and_return([
                                                             web_conference_plugin_mock("big_blue_button", {
                                                                                          domain: "bbb.instructure.com",
                                                                                          secret_dec: "secret",
                                                                                          send_avatar: true,
                                                                                        })
                                                           ])
      @course = course_factory
      user_with_communication_channel
      @course.enroll_teacher(@user).accept
      @create_time = (Time.zone.now.to_f * 1000).to_i # Time since epoch in milliseconds
      @conference = BigBlueButtonConference.create!(
        title: "my conference",
        user: @user,
        context: @course
      )
      @conference.settings[:create_time] = @create_time
    end

    it "retrieves a config hash correctly" do
      config = @conference.config
      expect(config).not_to be_nil
      expect(config[:conference_type]).to eql("BigBlueButton")
      expect(config[:class_name]).to eql("BigBlueButtonConference")
    end

    it "generates join urls correctly" do
      expect(@conference.config).not_to be_nil
      # set some vars so it thinks it's been created and doesn't do an api call
      @conference.conference_key = "test"
      @conference.settings[:admin_key] = "admin"
      @conference.settings[:user_key] = "user"
      @conference.save
      pronouns = user_factory.pronouns
      params = {
        fullName: user_factory.name,
        meetingID: @conference.conference_key,
        avatarUrl: user_factory.avatar_url,
        userID: user_factory.id,
        createTime: @conference.settings[:create_time]
      }
      params[:userdataPronouns] = pronouns unless pronouns.nil?
      admin_params = params.merge(password: "admin").to_query
      user_params = params.merge(password: "user").to_query
      expect(@conference.admin_join_url(@user)).to eql("https://bbb.instructure.com/bigbluebutton/api/join?#{admin_params}&checksum=" +
        Digest::SHA1.hexdigest("join#{admin_params}secret"))
      expect(@conference.participant_join_url(@user)).to eql("https://bbb.instructure.com/bigbluebutton/api/join?#{user_params}&checksum=" +
        Digest::SHA1.hexdigest("join#{user_params}secret"))
    end

    it "confirms valid config" do
      expect(BigBlueButtonConference.new).to be_valid_config
      expect(BigBlueButtonConference.new(conference_type: "BigBlueButton")).to be_valid_config
    end

    it "recreates the conference" do
      allow(@conference).to receive(:send_request).with(:create, anything).and_return({ createTime: @create_time })
      expect(@conference.craft_url(@user)).to match(%r{\Ahttps://bbb\.instructure\.com/bigbluebutton/api/join})
      # load a new instance to clear out @conference_active
      @conference = WebConference.find(@conference.id)
      allow(@conference).to receive(:send_request).with(:create, anything).and_return({ createTime: @create_time })
      expect(@conference.craft_url(@user)).to match(%r{\Ahttps://bbb\.instructure\.com/bigbluebutton/api/join})
    end

    it "does not recreate the conference if it is active" do
      expect(@conference).to receive(:send_request).once.with(:create, anything).and_return({
                                                                                              createTime: @create_time,
                                                                                            })
      @conference.initiate_conference
      expect(@conference).to be_active
      expect(@conference.craft_url(@user)).to match(%r{\Ahttps://bbb\.instructure\.com/bigbluebutton/api/join})
    end

    it "has a well formed user string as for recording_user_ready" do
      expect(@conference.recording_ready_user).to eq "#{@user["name"]} <#{@user.email}>"
    end

    it "has a well formed user string as for recording_user_ready in a group context" do
      group1 = @course.groups.create!(name: "group 1")
      group_conference = BigBlueButtonConference.create!(
        title: "my group conference",
        user: @user,
        context: group1
      )
      expect(group_conference.recording_ready_user).to eq "#{@user["name"]} <#{@user.email}>"
    end

    it "return nil if a request times out" do
      allow(CanvasHttp).to receive(:get).and_raise(Timeout::Error)
      expect(@conference.initiate_conference).to be_nil
    end
  end

  describe "plugin setting recording_enabled is enabled" do
    let(:get_recordings_fixture) { Rails.root.join("spec/fixtures/files/conferences/big_blue_button_get_recordings_two.json").read }
    let(:get_recordings_bulk_fixture) { Rails.root.join("spec/fixtures/files/conferences/big_blue_button_get_recordings_bulk.json").read }

    before do
      allow(WebConference).to receive(:plugins).and_return([
                                                             web_conference_plugin_mock("big_blue_button", {
                                                                                          domain: "bbb.instructure.com",
                                                                                          secret_dec: "secret",
                                                                                          recording_enabled: true,
                                                                                          use_fallback: true,
                                                                                        })
                                                           ])
      @bbb = BigBlueButtonConference.new
      @bbb.user_settings = { record: true }
      @bbb.user = user_factory
      @bbb.context = course_factory
      @bbb.save!
    end

    it "has visible record user_setting" do
      expect(BigBlueButtonConference.user_setting_fields[:record][:visible].call).to be_truthy
    end

    it "sends course data if parent is a course" do
      allow(@bbb).to receive(:send_request)
      @bbb.initiate_conference
      expect(@bbb).to have_received(:send_request).with(:create, hash_including(bbbCanvasCourseName: @course.name))
    end

    it "sends record flag if record user_setting is set" do
      allow(@bbb).to receive(:send_request)
      @bbb.initiate_conference
      expect(@bbb).to have_received(:send_request).with(:create, hash_including(record: true))
    end

    it "does not send record flag if record user setting is unset" do
      allow(@bbb).to receive(:send_request)
      @bbb.user_settings = { record: false }
      @bbb.save!
      @bbb.initiate_conference
      expect(@bbb).to have_received(:send_request).with(:create, hash_including(record: false))
    end

    it "initiates with the correct default values when bbb_modal_update is OFF" do
      Account.site_admin.disable_feature! :bbb_modal_update
      allow(@bbb).to receive(:send_request).and_return({ createTime: Time.now })
      allow(InstStatsd::Statsd).to receive(:increment)

      # these are the defaults defined in the BigBlueButtonConference model
      @bbb.user_settings = {
        record: false,
        scheduled_date: false,
        create_time: false,
        share_webcam: true,
        share_microphone: true,
        send_public_chat: true,
        send_private_chat: true,
        enable_waiting_room: false,
        share_other_webcams: true
      }

      @bbb.save!
      @bbb.initiate_conference
      expect(@bbb).to have_received(:send_request).with(:create, hash_including(record: false))
      expect(@bbb).to have_received(:send_request).with(:create, hash_excluding(
                                                                   {
                                                                     lockSettingsDisableCam: :any,
                                                                     lockSettingsDisableMic: :any,
                                                                     lockSettingsDisablePrivateChat: :any,
                                                                     lockSettingsDisablePublicChat: :any,
                                                                     webcamsOnlyForModerator: :any,
                                                                     guestPolicy: :any
                                                                   }
                                                                 ))
      expect(InstStatsd::Statsd).to have_received(:increment).with("bigbluebutton.started")

      # we will only track these settings when we explicitly include them in the request,
      # and not rely on BBB provider defaults
      expect(InstStatsd::Statsd).not_to have_received(:increment).with("bigbluebutton.start.setting.record")
      expect(InstStatsd::Statsd).not_to have_received(:increment).with("bigbluebutton.start.setting.share_webcam")
      expect(InstStatsd::Statsd).not_to have_received(:increment).with("bigbluebutton.start.setting.share_microphone")
      expect(InstStatsd::Statsd).not_to have_received(:increment).with("bigbluebutton.start.setting.send_public_chat")
      expect(InstStatsd::Statsd).not_to have_received(:increment).with("bigbluebutton.start.setting.send_private_chat")
      expect(InstStatsd::Statsd).not_to have_received(:increment).with("bigbluebutton.start.setting.enable_waiting_room")
      expect(InstStatsd::Statsd).not_to have_received(:increment).with("bigbluebutton.start.setting.share_other_webcams")
    end

    context "when :bbb_modal_update is ON" do
      before :once do
        Account.site_admin.enable_feature! :bbb_modal_update
      end

      it "send the correct bbb_modal_update default params" do
        allow(@bbb).to receive(:send_request).and_return({ createTime: Time.now })
        allow(InstStatsd::Statsd).to receive(:increment)

        # these are the defaults defined in the BigBlueButtonConference model
        @bbb.user_settings = {
          record: false,
          scheduled_date: false,
          create_time: false,
          share_webcam: true,
          share_microphone: true,
          send_public_chat: true,
          send_private_chat: true,
          enable_waiting_room: false,
          share_other_webcams: true
        }

        @bbb.save!
        @bbb.initiate_conference
        expect(@bbb).to have_received(:send_request).with(:create, hash_including(
                                                                     record: false,
                                                                     lockSettingsDisableCam: false,
                                                                     lockSettingsDisableMic: false,
                                                                     lockSettingsDisablePrivateChat: false,
                                                                     lockSettingsDisablePublicChat: false,
                                                                     webcamsOnlyForModerator: false,
                                                                     guestPolicy: "ALWAYS_ACCEPT"
                                                                   ))
        expect(InstStatsd::Statsd).to have_received(:increment).with("bigbluebutton.started")

        expect(InstStatsd::Statsd).not_to have_received(:increment).with("bigbluebutton.start.setting.record")
        expect(InstStatsd::Statsd).to have_received(:increment).with("bigbluebutton.start.setting.share_webcam")
        expect(InstStatsd::Statsd).to have_received(:increment).with("bigbluebutton.start.setting.share_microphone")
        expect(InstStatsd::Statsd).to have_received(:increment).with("bigbluebutton.start.setting.send_public_chat")
        expect(InstStatsd::Statsd).to have_received(:increment).with("bigbluebutton.start.setting.send_private_chat")
        expect(InstStatsd::Statsd).to have_received(:increment).with("bigbluebutton.start.setting.share_other_webcams")
        expect(InstStatsd::Statsd).not_to have_received(:increment).with("bigbluebutton.start.setting.enable_waiting_room")
      end

      it "send the correct bbb_modal_update supplied params" do
        allow(@bbb).to receive(:send_request).and_return({ createTime: Time.now })
        allow(InstStatsd::Statsd).to receive(:increment)

        # these are the opposites of the defaults
        @bbb.user_settings = {
          record: true,
          scheduled_date: false,
          create_time: false,
          share_webcam: false,
          share_microphone: false,
          send_public_chat: false,
          send_private_chat: false,
          enable_waiting_room: true,
          share_other_webcams: false
        }

        @bbb.save!
        @bbb.initiate_conference
        expect(@bbb).to have_received(:send_request).with(:create, hash_including(
                                                                     record: true,
                                                                     lockSettingsDisableCam: true,
                                                                     lockSettingsDisableMic: true,
                                                                     lockSettingsDisablePrivateChat: true,
                                                                     lockSettingsDisablePublicChat: true,
                                                                     webcamsOnlyForModerator: true,
                                                                     guestPolicy: "ASK_MODERATOR"
                                                                   ))

        expect(InstStatsd::Statsd).to have_received(:increment).with("bigbluebutton.started")

        expect(InstStatsd::Statsd).to have_received(:increment).with("bigbluebutton.start.setting.record")
        expect(InstStatsd::Statsd).not_to have_received(:increment).with("bigbluebutton.start.setting.share_webcam")
        expect(InstStatsd::Statsd).not_to have_received(:increment).with("bigbluebutton.start.setting.share_microphone")
        expect(InstStatsd::Statsd).not_to have_received(:increment).with("bigbluebutton.start.setting.send_public_chat")
        expect(InstStatsd::Statsd).not_to have_received(:increment).with("bigbluebutton.start.setting.send_private_chat")
        expect(InstStatsd::Statsd).not_to have_received(:increment).with("bigbluebutton.start.setting.share_other_webcams")
        expect(InstStatsd::Statsd).to have_received(:increment).with("bigbluebutton.start.setting.enable_waiting_room")
      end
    end

    it "properly serializes a response with no recordings" do
      response = { returncode: "SUCCESS",
                   recordings: "\n  ",
                   messageKey: "noRecordings",
                   message: "There are no recordings for the meeting(s)." }
      allow(@bbb).to receive_messages(conference_key: "12345", send_request: response)
      expect(@bbb.recordings).to eq []
    end

    it "properly serializes a response with recordings" do
      response = JSON.parse(get_recordings_fixture, { symbolize_names: true })
      allow(@bbb).to receive_messages(conference_key: "12345", send_request: response)
      expect(@bbb.recordings).not_to eq []
    end

    it "does not have duration_minutes set to 0" do
      response = JSON.parse(get_recordings_fixture, { symbolize_names: true })
      allow(@bbb).to receive_messages(conference_key: "12345", send_request: response)
      @bbb.recordings.each do |recording|
        expect(recording[:duration_minutes]).not_to eq(0)
      end
    end

    it "includes whether to show to students (and be true for everything but statistics)" do
      response = JSON.parse(get_recordings_fixture, { symbolize_names: true })
      allow(@bbb).to receive_messages(conference_key: "12345", send_request: response)
      @bbb.recordings.each do |recording|
        recording[:playback_formats].each do |format|
          expect(format[:show_to_students]).to eq(format[:type] != "statistics")
        end
      end
    end

    it "includes translated type for playback format" do
      response = JSON.parse(get_recordings_fixture, { symbolize_names: true })
      allow(@bbb).to receive_messages(conference_key: "12345", send_request: response)
      @bbb.recordings.each do |recording|
        recording[:playback_formats].each do |format|
          # turns video into Video, etc.
          expect(format[:translated_type]).to eq(format[:type].upcase_first)
        end
      end
    end

    describe "looking for recordings based on user setting" do
      before(:once) do
        @bbb = BigBlueButtonConference.new(user: user_factory, context: course_factory)
        # set some vars so it thinks it's been created and doesn't do an api call
        @bbb.conference_key = "test"
        @bbb.settings[:admin_key] = "admin"
        @bbb.settings[:user_key] = "user"
        @bbb.save
      end

      it "doesn't look if setting is false" do
        @bbb.save
        expect(@bbb).not_to receive(:send_request)
        @bbb.recordings
      end

      it "does look if setting is true" do
        @bbb.user_settings = { record: true }
        @bbb.save
        expect(@bbb).to receive(:send_request)
        @bbb.recordings
      end
    end

    describe "delete recording" do
      before(:once) do
        @bbb = BigBlueButtonConference.new(user: user_factory, context: course_factory)
        # set some vars so it thinks it's been created and doesn't do an api call
        @bbb.conference_key = "test"
        @bbb.settings[:admin_key] = "admin"
        @bbb.settings[:user_key] = "user"
        @bbb.save
      end

      it "doesn't delete anything if record_id = nil" do
        recording_id = nil
        allow(@bbb).to receive(:send_request)
        response = @bbb.delete_recording(recording_id)
        expect(response[:deleted]).to be false
      end

      it "doesn't delete the recording if record_id is not found" do
        recording_id = ""
        allow(@bbb).to receive(:send_request).and_return({ returncode: "SUCCESS", deleted: "false" })
        response = @bbb.delete_recording(recording_id)
        expect(response[:deleted]).to be false
      end

      it "does delete the recording if record_id is found" do
        recording_id = "abc123-xyz"
        allow(@bbb).to receive(:send_request).and_return({ returncode: "SUCCESS", deleted: "true" })
        response = @bbb.delete_recording(recording_id)
        expect(response[:deleted]).to be true
      end
    end

    describe "recording preloading" do
      it "loads up all recordings in a single api call" do
        @bbb2 = BigBlueButtonConference.create!(context: @bbb.context, user: @bbb.user, user_settings: @bbb.user_settings)
        allow(@bbb).to receive(:conference_key).and_return("instructure_web_conference_somemeetingkey1")
        allow(@bbb2).to receive(:conference_key).and_return("instructure_web_conference_somemeetingkey2")

        response = JSON.parse(get_recordings_bulk_fixture, { symbolize_names: true })
        allow(BigBlueButtonConference).to receive(:send_request).and_return(response)

        BigBlueButtonConference.preload_recordings([@bbb, @bbb2])
        [@bbb, @bbb2].each { |c| expect(c).to_not receive(:send_request) } # shouldn't need to send individual requests anymore
        expect(@bbb.recordings.pluck(:recording_id)).to match_array(["somerecordingidformeeting1a", "somerecordingidformeeting1b"])
        expect(@bbb2.recordings.pluck(:recording_id)).to match_array(["somerecordingidformeeting2"])
      end

      it "makes a separate api call for old conferences" do
        old_config = {
          domain: "bbb_old.instructure.com",
          secret_dec: "old_secret",
        }.with_indifferent_access
        allow(Canvas::Plugin.find(:big_blue_button_fallback)).to receive(:settings).and_return(old_config)

        @bbb2 = BigBlueButtonConference.create!(context: @bbb.context, user: @bbb.user, user_settings: @bbb.user_settings)
        @bbb2.settings[:domain] = "bbb.instructure.com" # use the current config
        allow(@bbb).to receive(:conference_key).and_return("instructure_web_conference_somemeetingkey1")
        allow(@bbb2).to receive(:conference_key).and_return("instructure_web_conference_somemeetingkey2")

        response = JSON.parse(get_recordings_bulk_fixture, { symbolize_names: true })
        expect(BigBlueButtonConference).to receive(:send_request)
          .with(:getRecordings, { meetingID: "instructure_web_conference_somemeetingkey1" }, use_fallback_config: true)
          .and_return(response)
        expect(BigBlueButtonConference).to receive(:send_request)
          .with(:getRecordings, { meetingID: "instructure_web_conference_somemeetingkey2" }, use_fallback_config: false)
          .and_return(response)

        BigBlueButtonConference.preload_recordings([@bbb, @bbb2])
        [@bbb, @bbb2].each { |c| expect(c).to_not receive(:send_request) } # shouldn't need to send individual requests anymore
        expect(@bbb.recordings.pluck(:recording_id)).to match_array(["somerecordingidformeeting1a", "somerecordingidformeeting1b"])
        expect(@bbb2.recordings.pluck(:recording_id)).to match_array(["somerecordingidformeeting2"])
      end

      it "does not make a call for conferences without keys" do
        allow(@bbb).to receive(:conference_key).and_return(nil)
        expect(BigBlueButtonConference).not_to receive(:send_request)

        BigBlueButtonConference.preload_recordings([@bbb])
      end

      it "makes not make an empty call when preloading for old conferences" do
        old_config = {
          domain: "bbb_old.instructure.com",
          secret_dec: "old_secret",
        }.with_indifferent_access
        allow(Canvas::Plugin.find(:big_blue_button_fallback)).to receive(:settings).and_return(old_config)

        @bbb2 = BigBlueButtonConference.create!(context: @bbb.context, user: @bbb.user, user_settings: @bbb.user_settings)
        @bbb2.settings[:domain] = "bbb.instructure.com" # use the current config
        allow(@bbb).to receive(:conference_key).and_return(nil)
        allow(@bbb2).to receive(:conference_key).and_return("instructure_web_conference_somemeetingkey2")

        response = JSON.parse(get_recordings_bulk_fixture, { symbolize_names: true })
        # don't make an empty call for the old fallback config because the conference didn't have a key
        expect(BigBlueButtonConference).to receive(:send_request)
          .with(:getRecordings, { meetingID: "instructure_web_conference_somemeetingkey2" }, use_fallback_config: false)
          .and_return(response)

        BigBlueButtonConference.preload_recordings([@bbb, @bbb2])
        expect(@bbb2).to_not receive(:send_request)
        expect(@bbb2.recordings.pluck(:recording_id)).to match_array(["somerecordingidformeeting2"])
      end
    end
  end

  describe "plugin setting recording disabled" do
    before do
      allow(WebConference).to receive(:plugins).and_return([
                                                             web_conference_plugin_mock("big_blue_button", {
                                                                                          domain: "bbb.instructure.com",
                                                                                          secret_dec: "secret",
                                                                                          recording_enabled: false,
                                                                                        })
                                                           ])
    end

    it "has invisible record user_setting" do
      expect(BigBlueButtonConference.user_setting_fields[:record][:visible].call).to be_falsey
    end

    it "does not send record flag even if record user_setting is set" do
      bbb = BigBlueButtonConference.new
      bbb.user_settings = { record: true }
      bbb.user = user_factory
      bbb.context = course_factory
      bbb.save!
      expect(bbb).to receive(:send_request).with(:create, hash_including(record: false))
      bbb.initiate_conference
      expect(bbb.user_settings[:record]).to be_falsey
    end
  end

  describe "config fallback" do
    let(:bbb_config) do
      {
        domain: "bbb_new.instructure.com",
        secret_dec: "new_secret",
        use_fallback: true,
      }
    end

    before do
      old_config = {
        domain: "bbb_old.instructure.com",
        secret_dec: "old_secret",
      }.with_indifferent_access
      allow(Canvas::Plugin.find(:big_blue_button_fallback)).to receive(:settings).and_return(old_config)

      allow(WebConference).to receive(:plugins).and_return([
                                                             web_conference_plugin_mock("big_blue_button", bbb_config)
                                                           ])
    end

    it "saves the domain for the current config when initiating the conference" do
      bbb = BigBlueButtonConference.create!(user: user_factory, context: course_factory)
      expect(CanvasHttp).to receive(:get).with(/bbb_new\.instructure\.com/, anything) # should initiate on the current config
      bbb.initiate_conference
      expect(bbb.settings[:domain]).to eq "bbb_new.instructure.com"
    end

    it "generates a url with the current config if the saved domain matches" do
      bbb = BigBlueButtonConference.create!(user: user_factory, context: course_factory)
      bbb.settings[:domain] = "bbb_new.instructure.com"
      expect(CanvasHttp).to receive(:get).with(/bbb_new\.instructure\.com/, anything)
      bbb.send(:send_request, :action, { query: 1 })
    end

    it "generates a url with the fallback config if the saved domain doesn't match" do
      bbb = BigBlueButtonConference.create!(user: user_factory, context: course_factory)
      bbb.settings[:domain] = "bbb_old.instructure.com"
      expect(CanvasHttp).to receive(:get).with(/bbb_old\.instructure\.com/, anything)
      bbb.send(:send_request, :action, { query: 1 })
    end

    it "generates a url with the fallback config if the saved domain wasn't set (i.e. old data)" do
      bbb = BigBlueButtonConference.create!(user: user_factory, context: course_factory)
      expect(CanvasHttp).to receive(:get).with(/bbb_old\.instructure\.com/, anything)
      bbb.send(:send_request, :action, { query: 1 })
    end

    it "generates a url with the current config if fallback is disabled" do
      allow(WebConference).to receive(:plugins).and_return([
                                                             web_conference_plugin_mock("big_blue_button", bbb_config.merge(use_fallback: false))
                                                           ])
      bbb = BigBlueButtonConference.create!(user: user_factory, context: course_factory)
      expect(CanvasHttp).to receive(:get).with(/bbb_new\.instructure\.com/, anything)
      bbb.send(:send_request, :action, { query: 1 })
    end

    it "generates a url with the current config if the saved domain wasn't set but there is no fallback configured" do
      allow(Canvas::Plugin.find(:big_blue_button_fallback)).to receive(:settings).and_return(nil)
      bbb = BigBlueButtonConference.create!(user: user_factory, context: course_factory)
      expect(CanvasHttp).to receive(:get).with(/bbb_new\.instructure\.com/, anything)
      bbb.send(:send_request, :action, { query: 1 })
    end
  end
end
