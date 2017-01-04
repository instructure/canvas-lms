require 'spec_helper'
require_dependency "users/creation_notify_policy"

module Users
  describe CreationNotifyPolicy do
    describe "#is_self_registration?" do
      it "is true when forced" do
        policy = CreationNotifyPolicy.new(false, {force_self_registration: '1'})
        expect(policy.is_self_registration?).to be(true)
      end

      it "is opposite the management ability provide" do
        policy = CreationNotifyPolicy.new(false, {})
        expect(policy.is_self_registration?).to be(true)
        policy = CreationNotifyPolicy.new(true, {})
        expect(policy.is_self_registration?).to be(false)
      end
    end

    describe "#dispatch!" do
      let(:user){ stub() }
      let(:pseudonym) { stub() }
      let(:channel){ stub() }

      context "for self_registration" do
        let(:policy){ CreationNotifyPolicy.new(true, {force_self_registration: true}) }
        before{ channel.stubs(has_merge_candidates?: false) }

        it "sends confirmation notification" do
          user.stubs(pre_registered?: true)
          pseudonym.expects(:send_confirmation!)
          result = policy.dispatch!(user, pseudonym, channel)
          expect(result).to be(true)
        end

        it "sends the registration notification if the user is pending or registered" do
          user.stubs(pre_registered?: false, registered?: false)
          pseudonym.expects(:send_registration_notification!)
          result = policy.dispatch!(user, pseudonym, channel)
          expect(result).to be(true)
        end
      end

      context "when the user isn't yet registered" do
        before do
          user.stubs(registered?: false)
          channel.stubs(has_merge_candidates?: false)
        end

        it "sends the registration notification if should notify" do
          policy = CreationNotifyPolicy.new(true, {send_confirmation: '1'})
          pseudonym.expects(:send_registration_notification!)
          result = policy.dispatch!(user, pseudonym, channel)
          expect(result).to be(true)
        end

        it "doesnt send the registration notification if shouldnt notify" do
          policy = CreationNotifyPolicy.new(true, {send_confirmation: '0'})
          pseudonym.expects(:send_registration_notification!).never
          result = policy.dispatch!(user, pseudonym, channel)
          expect(result).to be(false)
        end
      end

      context "when the user is registered" do
        before{ user.stubs(registered?: true) }
        let(:policy){ CreationNotifyPolicy.new(true, {}) }

        it "sends the merge notification if there are merge candidates" do
          channel.stubs(has_merge_candidates?: true)
          channel.expects(:send_merge_notification!)
          result = policy.dispatch!(user, pseudonym, channel)
          expect(result).to be(false)
        end

        it "does nothing without merge candidates" do
          channel.stubs(has_merge_candidates?: false)
          channel.expects(:send_merge_notification!).never
          result = policy.dispatch!(user, pseudonym, channel)
          expect(result).to be(false)
        end
      end

    end
  end
end
