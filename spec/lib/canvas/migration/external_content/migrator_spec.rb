# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

require_relative "../../../../spec_helper"

describe Canvas::Migration::ExternalContent::Migrator do
  before :once do
    course_with_teacher(active_all: true)
    @ce = @course.content_exports.create!
  end

  let(:migrator) { Canvas::Migration::ExternalContent::Migrator }

  describe "#begin_exports" do
    before :once do
      quiz = @course.quizzes.create!(title: "new_quizzes")
      Account.default.context_external_tools.create!(
        name: "Quizzes.Next",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        tool_id: "Quizzes 2",
        url: "http://example.com/launch"
      )
      @ce = @course.content_exports.create!(
        export_type: ContentExport::QUIZZES2,
        selected_content: quiz.id,
        user: @user
      )
      @course.root_account.settings[:provision] = { "lti" => "lti url" }
      @course.root_account.save!
    end

    context "new_quizzes_common_cartridge ff disabled" do
      describe "regular QTI export" do
        it "should export through the regular workflow" do
          expect(migrator).to receive(:should_load_new_quizzes_export?).and_return(false)
          expect(QuizzesNext::ExportService).to receive(:begin_export)

          migrator.begin_exports(@course, @ce, selective: true, exported_assets: @ce.exported_assets.to_a)
        end
      end
    end

    context "new_quizzes_common_cartridge ff enabled" do
      describe "Common Cartridge export with New Quizzes" do
        before do
          allow(NewQuizzesFeaturesHelper).to receive(:new_quizzes_common_cartridge_enabled?).and_return(true)
        end

        it "should skip the regular workflow" do
          expect(migrator).to receive(:should_load_new_quizzes_export?).and_return(true)
          expect(QuizzesNext::ExportService).to_not receive(:begin_export)

          migrator.begin_exports(@course, @ce, selective: true, exported_assets: @ce.exported_assets.to_a)
        end
      end
    end
  end
end
