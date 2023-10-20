# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

describe Loaders::SISIDLoader do
  it "works" do
    course_with_student(active_all: true)
    @course.update!(sis_source_id: "importedCourse")
    GraphQL::Batch.batch do
      course_loader = Loaders::SISIDLoader.for(Course)
      course_loader.load("importedCourse").then do |course|
        expect(course).to eq @course
      end
      course_loader.load(-1).then do |course|
        expect(course).to be_nil
      end
    end
  end

  context "multiple accounts on a single shard" do
    # shared across accounts on a single shard
    sis_source_id = "12345"

    # unique to each account
    sis_source_id_account_1 = "111-111"
    sis_source_id_account_2 = "222-222"

    before do
      # create accounts on same shard
      @account_1 = Account.create!
      @account_2 = Account.create!

      # create terms on different accounts
      @account_1_term = @account_1.enrollment_terms.create!(name: "term_1", sis_source_id:)
      @account_2_term = @account_2.enrollment_terms.create!(name: "term_2", sis_source_id:)

      # create terms unique to each account
      @account_1_only_term = @account_1.enrollment_terms.create!(name: "account_1 only term", sis_source_id: sis_source_id_account_1)
      @account_2_only_term = @account_2.enrollment_terms.create!(name: "account_2 only term", sis_source_id: sis_source_id_account_2)
    end

    it "loads unscoped terms when no root_account is provided" do
      GraphQL::Batch.batch do
        term_loader = Loaders::SISIDLoader.for(EnrollmentTerm)

        term_loader.load(sis_source_id).then do |term|
          expect(term).to eq @account_1_term
        end
      end
    end

    it "loads term from different scoped accounts with same sis_source_id" do
      GraphQL::Batch.batch do
        term_1_loader = Loaders::SISIDLoader.for(EnrollmentTerm, root_account: @account_1)
        term_2_loader = Loaders::SISIDLoader.for(EnrollmentTerm, root_account: @account_2)

        # sis_source_id is the same across account_1 AND account_2
        term_1_loader.load(sis_source_id).then do |term|
          expect(term).to eq @account_1_term
        end

        term_2_loader.load(sis_source_id).then do |term|
          expect(term).to eq @account_2_term
        end
      end
    end

    it "sequentially loads multiple terms scoped to account_1" do
      GraphQL::Batch.batch do
        term_loader = Loaders::SISIDLoader.for(EnrollmentTerm, root_account: @account_1)

        term_loader.load(sis_source_id).then do |term|
          expect(term).to eq @account_1_term
        end

        term_loader.load(sis_source_id_account_1).then do |term|
          expect(term).to eq @account_1_only_term
        end
      end
    end

    it "sequentially loads multiple terms scoped to account_2" do
      GraphQL::Batch.batch do
        term_loader = Loaders::SISIDLoader.for(EnrollmentTerm, root_account: @account_2)

        term_loader.load(sis_source_id).then do |term|
          expect(term).to eq @account_2_term
        end

        term_loader.load(sis_source_id_account_2).then do |term|
          expect(term).to eq @account_2_only_term
        end
      end
    end

    it "returns nil when loading an invalid sis_source_id scoped to account_1" do
      invalid_sis_source_id = "invalid-id"

      GraphQL::Batch.batch do
        term_loader = Loaders::SISIDLoader.for(EnrollmentTerm, root_account: @account_1)

        term_loader.load(invalid_sis_source_id).then do |term|
          expect(term).to be_nil
        end
      end
    end

    it "returns nil when loading an invalid sis_source_id (not scoped)" do
      invalid_sis_source_id = "invalid-id"

      GraphQL::Batch.batch do
        term_loader = Loaders::SISIDLoader.for(EnrollmentTerm)

        term_loader.load(invalid_sis_source_id).then do |term|
          expect(term).to be_nil
        end
      end
    end

    it "loads nothing when scoped to a valid account that doesn’t have term with sis_source_id" do
      account_with_no_terms = Account.new

      GraphQL::Batch.batch do
        term_loader = Loaders::SISIDLoader.for(EnrollmentTerm, root_account: account_with_no_terms)

        term_loader.load(sis_source_id).then do |term|
          expect(term).to be_nil
        end
      end
    end

    it "loads nothing when scoped to an invalid account" do
      invalid_account_id = 9999 # non-existent account ID

      GraphQL::Batch.batch do
        term_loader = Loaders::SISIDLoader.for(EnrollmentTerm, root_account: invalid_account_id)

        term_loader.load(sis_source_id).then do |term|
          expect(term).to be_nil
        end
      end
    end
  end
end
