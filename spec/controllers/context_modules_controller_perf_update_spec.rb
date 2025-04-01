# frozen_string_literal: true

# Copyright (C) 2025 - present Instructure, Inc.
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

describe ContextModulesController do
  describe "GET 'index'" do
    subject { get :index, params: { course_id: @course.id } }

    render_views

    before do
      course_with_teacher_logged_in(active_all: true)
      @course.context_modules.create!(name: "Test Module")
    end

    context "when modules_perf enabled" do
      before do
        @course.account.enable_feature!(:modules_perf)
      end

      it "exports proper environment variable with the flag ON" do
        subject
        expect(assigns[:js_env][:FEATURE_MODULES_PERF]).to be_truthy
      end
    end

    context "when modules_perf disabled" do
      before do
        @course.account.disable_feature!(:modules_perf)
      end

      it "exports proper environment variable with the flag OFF" do
        subject
        expect(assigns[:js_env][:FEATURE_MODULES_PERF]).to be_falsey
      end
    end
  end

  describe "GET 'items_html'" do
    subject { get "items_html", params: { course_id: @course.id, context_module_id: context_module.id } }

    render_views

    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
    end

    let(:page1) { @course.wiki_pages.create! title: "title1" }
    let(:page2) { @course.wiki_pages.create! title: "title2" }

    let(:context_module) do
      context_module = @course.context_modules.create!
      context_module.add_item({ type: "wiki_page", id: page1.id }, nil, position: 2)
      context_module.add_item({ type: "wiki_page", id: page2.id }, nil, position: 1)
      context_module
    end

    context "when modules_perf enabled" do
      before do
        @course.account.enable_feature!(:modules_perf)
      end

      context "when there is no user session" do
        it "redirect to login page" do
          subject
          assert_unauthorized
        end
      end

      context "when there is a user session" do
        before do
          user_session(@user)
        end

        context "when the provided module id exist" do
          it "renders the template" do
            subject
            assert_status(200)
            expect(response.body).to include("<ul class=\"ig-list items context_module_items")
          end

          it "has the @module variable" do
            subject
            expect(assigns(:module)).to eql(context_module)
          end

          it "has the @items variable" do
            subject
            expect(assigns(:items).length).to be(2)
            item1_position2 = context_module.content_tags.find_by(content_id: page1.id, context_module_id: context_module.id)
            item2_position1 = context_module.content_tags.find_by(content_id: page2.id, context_module_id: context_module.id)
            expect(assigns(:items).first).to eql(item2_position1)
            expect(assigns(:items).second).to eql(item1_position2)
          end

          it "has the @menu_tools variable" do
            finder_double = double("Lti::ContextToolFinder")
            tool_double_1 = double("Tool 1", has_placement?: true)
            tool_double_2 = double("Tool 2", has_placement?: false)

            allow(Lti::ContextToolFinder)
              .to receive(:new)
              .with(@course, placements: anything, current_user: anything)
              .and_return(finder_double)
            allow(finder_double).to receive(:all_tools_sorted_array).and_return([tool_double_1, tool_double_2])

            subject

            expect(assigns(:menu_tools).values).to all(eq([tool_double_1]))
          end

          describe "rights load" do
            before { subject }

            it { expect(assigns(:can_view)).to_not be_nil }
            it { expect(assigns(:can_add)).to_not be_nil }
            it { expect(assigns(:can_edit)).to_not be_nil }
            it { expect(assigns(:can_delete)).to_not be_nil }
            it { expect(assigns(:can_view_grades)).to_not be_nil }
            it { expect(assigns(:is_student)).to_not be_nil }
            it { expect(assigns(:can_view_unpublished)).to_not be_nil }
          end
        end

        context "when the provided module id not exist" do
          subject { get "items_html", params: { course_id: @course.id, context_module_id: "random_id" } }

          it "renders 404" do
            subject
            assert_status(404)
          end
        end
      end
    end

    context "when modules_perf disabled" do
      before do
        @course.account.disable_feature!(:modules_perf)
      end

      it "renders 404" do
        subject
        assert_status(404)
      end
    end
  end
end
