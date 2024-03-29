# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

require "spec_helper"
require_relative "../graphql_spec_helper"

describe Mutations::UpdateMyInboxSettings do
  include GraphQLSpecHelper

  before do
    Account.site_admin.enable_feature!(:inbox_settings)
  end

  let(:account) { Account.create! }
  let(:course) { account.courses.create! }
  let(:teacher) { course.enroll_teacher(User.create!, enrollment_state: "active").user }
  let(:user_id) { teacher.id }
  let(:context) { { current_user: teacher, domain_root_account: account } }
  let(:root_account_id) { account.id }
  let(:use_signature) { true }
  let(:use_out_of_office) { true }
  let(:signature) { "John Doe" }
  let(:updated_signature) { "John Doe Updated" }
  let(:out_of_office_first_date) { "2024-04-09T00:00:00Z" }
  let(:out_of_office_last_date) { "2024-04-10T00:00:00Z" }
  let(:out_of_office_subject) { "Out of office" }
  let(:out_of_office_message) { "Out of office for one week" }
  let(:inbox_settings_record) { Inbox::Repositories::InboxSettingsRepository::InboxSettingsRecord }

  def mutation_str(**attrs)
    <<~GQL
      mutation{
        updateMyInboxSettings(
          input: {
            #{gql_arguments("", **attrs)}
          }
        ) {
          myInboxSettings {
            userId
            useSignature
            signature
            useOutOfOffice
            outOfOfficeFirstDate
            outOfOfficeLastDate
            outOfOfficeSubject
            outOfOfficeMessage
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
  end

  def execute_query(mutation_str, context)
    CanvasSchema.execute(mutation_str, context:)
  end

  context "mutation" do
    context "new user inbox settings" do
      it "creates with default values" do
        result = execute_query(
          mutation_str(
            use_signature:,
            use_out_of_office:
          ),
          context
        )

        expect(result["errors"]).to be_nil
        expect(result.dig("data", "updateMyInboxSettings", "errors")).to be_nil
        result = result.dig("data", "updateMyInboxSettings", "myInboxSettings")
        record = inbox_settings_record.find_by(user_id:, root_account_id:)
        expect(result["userId"]).to eq user_id.to_s
        expect(result["useSignature"]).to eq use_signature
        expect(result["signature"]).to be_nil
        expect(result["useOutOfOffice"]).to eq use_out_of_office
        expect(result["outOfOfficeFirstDate"]).to be_nil
        expect(result["outOfOfficeLastDate"]).to be_nil
        expect(result["outOfOfficeSubject"]).to be_nil
        expect(result["outOfOfficeMessage"]).to be_nil
        expect(record.user_id).to eq user_id.to_s
        expect(record.use_signature).to eq use_signature
        expect(record.signature).to be_nil
        expect(record.use_out_of_office).to eq use_out_of_office
        expect(record.out_of_office_first_date).to be_nil
        expect(record.out_of_office_last_date).to be_nil
        expect(record.out_of_office_subject).to be_nil
        expect(record.out_of_office_message).to be_nil
      end

      it "creates with custom values when provided" do
        result = execute_query(
          mutation_str(
            use_signature:,
            signature:,
            use_out_of_office:,
            out_of_office_first_date:,
            out_of_office_last_date:,
            out_of_office_subject:,
            out_of_office_message:
          ),
          context
        )
        expect(result["errors"]).to be_nil
        expect(result.dig("data", "updateMyInboxSettings", "errors")).to be_nil
        result = result.dig("data", "updateMyInboxSettings", "myInboxSettings")
        record = inbox_settings_record.find_by(user_id:, root_account_id:)
        expect(result["userId"]).to eq user_id.to_s
        expect(result["useSignature"]).to eq use_signature
        expect(result["signature"]).to eq signature
        expect(result["useOutOfOffice"]).to eq use_out_of_office
        expect(result["outOfOfficeFirstDate"]).to eq Time.parse(out_of_office_first_date).iso8601
        expect(result["outOfOfficeLastDate"]).to eq Time.parse(out_of_office_last_date).iso8601
        expect(result["outOfOfficeSubject"]).to eq out_of_office_subject
        expect(result["outOfOfficeMessage"]).to eq out_of_office_message
        expect(record.user_id).to eq user_id.to_s
        expect(record.use_signature).to eq use_signature
        expect(record.signature).to eq signature
        expect(record.use_out_of_office).to eq use_out_of_office
        expect(record.out_of_office_first_date).to eq out_of_office_first_date
        expect(record.out_of_office_last_date).to eq out_of_office_last_date
        expect(record.out_of_office_subject).to eq out_of_office_subject
        expect(record.out_of_office_message).to eq out_of_office_message
      end
    end

    it "updates existing user inbox settings" do
      inbox_settings_record.new(user_id:, root_account_id:, use_signature:, use_out_of_office:).save!
      expect(inbox_settings_record.find_by(user_id:, root_account_id:).signature).to be_nil

      result = execute_query(
        mutation_str(
          use_signature:,
          signature: updated_signature,
          use_out_of_office:
        ),
        context
      )
      expect(result["errors"]).to be_nil
      expect(result.dig("data", "updateMyInboxSettings", "errors")).to be_nil
      result = result.dig("data", "updateMyInboxSettings", "myInboxSettings")
      record = inbox_settings_record.find_by(user_id:, root_account_id:)
      expect(result["userId"]).to eq user_id.to_s
      expect(result["useSignature"]).to eq use_signature
      expect(result["signature"]).to eq updated_signature
      expect(result["useOutOfOffice"]).to eq use_out_of_office
      expect(record.user_id).to eq user_id.to_s
      expect(record.use_signature).to eq use_signature
      expect(record.signature).to eq updated_signature
      expect(record.use_out_of_office).to eq use_out_of_office
    end
  end

  context "errors" do
    def expect_error(result, message)
      errors = result["errors"] || result.dig("data", "updateMyInboxSettings", "errors")
      expect(errors).not_to be_nil
      expect(errors.first["message"]).to include message
    end

    it "use_signature is required" do
      result = execute_query(
        mutation_str(
          use_out_of_office:
        ),
        context
      )
      expect_error(result, "Argument 'useSignature' on InputObject 'UpdateMyInboxSettingsInput' is required. Expected type Boolean!")
    end

    it "use_out_of_office is required" do
      result = execute_query(
        mutation_str(
          use_signature:
        ),
        context
      )
      expect_error(result, "Argument 'useOutOfOffice' on InputObject 'UpdateMyInboxSettingsInput' is required. Expected type Boolean!")
    end

    it "requires feature to be enabled" do
      Account.site_admin.disable_feature!(:inbox_settings)

      result = execute_query(
        mutation_str(
          use_signature:,
          use_out_of_office:
        ),
        context
      )
      expect_error(result, "inbox settings feature is disabled")
    end
  end
end
