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
    end

    context "when module_performance_improvement_is_enabled? enabled" do
      before do
        allow_any_instance_of(ContextModulesHelper)
          .to receive(:module_performance_improvement_is_enabled?)
          .and_return(true)
      end

      describe "FEATURE_MODULES_PERF" do
        it "exports proper environment variable with the flag ON" do
          subject
          expect(assigns[:js_env][:FEATURE_MODULES_PERF]).to be_truthy
        end
      end

      describe "EXPANDED_MODULES and COLLAPSED_MODULES" do
        context "when we don't have context module progression" do
          it "should assign empty array to @expanded_modules and @collapsed_modules" do
            subject
            expect(assigns(:expanded_modules)).to be_empty
            expect(assigns(:collapsed_modules)).to be_empty
          end

          it "should assign empty array to EXPANDED_MODULES and COLLAPSED_MODULES js env" do
            subject
            expect(assigns[:js_env][:EXPANDED_MODULES]).to be_empty
            expect(assigns[:js_env][:COLLAPSED_MODULES]).to be_empty
          end
        end

        context "when we have context module progression" do
          let(:context_module) { @course.context_modules.create! }
          let(:progression) { @user.context_module_progressions.create!(context_module:) }

          context "when progression is collapsed" do
            before do
              progression.update!(collapsed: true)
            end

            it "should assign empty array to @expanded_modules" do
              subject
              expect(assigns(:expanded_modules)).to be_empty
              expect(assigns(:collapsed_modules)).to eql([context_module.id])
            end

            it "should assign empty array to EXPANDED_MODULES js env" do
              subject
              expect(assigns[:js_env][:EXPANDED_MODULES]).to be_empty
              expect(assigns[:js_env][:COLLAPSED_MODULES]).to eql([context_module.id])
            end
          end

          context "when progression is expanded" do
            before do
              progression.update!(collapsed: false)
            end

            it "should assign empty array to @expanded_modules" do
              subject
              expect(assigns(:expanded_modules)).to eql([context_module.id])
              expect(assigns(:collapsed_modules)).to be_empty
            end

            it "should assign empty array to EXPANDED_MODULES and COLLAPSED_MODULES js env" do
              subject
              expect(assigns[:js_env][:EXPANDED_MODULES]).to eql([context_module.id])
              expect(assigns[:js_env][:COLLAPSED_MODULES]).to be_empty
            end
          end

          context "when progression is nil" do
            before do
              progression.update!(collapsed: nil)
            end

            it "should assign empty array to @expanded_modules and @collapsed_modules" do
              subject
              expect(assigns(:expanded_modules)).to be_empty
              expect(assigns(:collapsed_modules)).to be_empty
            end

            it "should assign empty array to EXPANDED_MODULES and COLLAPSED_MODULES js env" do
              subject
              expect(assigns[:js_env][:EXPANDED_MODULES]).to be_empty
              expect(assigns[:js_env][:COLLAPSED_MODULES]).to be_empty
            end
          end
        end
      end
    end

    context "when module_performance_improvement_is_enabled? disabled" do
      before do
        allow_any_instance_of(ContextModulesHelper)
          .to receive(:module_performance_improvement_is_enabled?)
          .and_return(false)
      end

      describe "FEATURE_MODULES_PERF" do
        it "exports proper environment variable with the flag OFF" do
          subject
          expect(assigns[:js_env][:FEATURE_MODULES_PERF]).to be_falsey
        end
      end

      describe "EXPANDED_MODULES" do
        it "should not assign the @expanded_modules" do
          subject
          expect(assigns(:expanded_modules)).to be_nil
        end

        it "should have empty EXPANDED_MODULES js env" do
          subject
          expect(assigns[:js_env][:EXPANDED_MODULES]).to be_empty
        end
      end
    end
  end

  describe "GET 'module_html'" do
    subject { get "module_html", params: { course_id: @course.id, context_module_id: context_module.id } }

    render_views

    before :once do
      course_with_teacher(active_all: true)
    end

    let(:page1) { @course.wiki_pages.create! title: "title1" }

    let(:context_module) do
      context_module = @course.context_modules.create!
      context_module.add_item({ type: "wiki_page", id: page1.id }, nil, position: 1)
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
            expect(response.body).to_not be_empty
          end

          it "has the @module_show_setting with show_student_only_module_id" do
            ref_id = 111
            @course.account.enable_feature!(:modules_student_module_selection)
            @course.update!(show_student_only_module_id: ref_id)

            subject
            expect(assigns(:module_show_setting)).to eql(ref_id)
          end

          it "has the @module_show_setting with show_teacher_only_module_id" do
            ref_id = 222
            @course.account.enable_feature!(:modules_teacher_module_selection)
            @course.update!(show_teacher_only_module_id: ref_id)

            subject
            expect(assigns(:module_show_setting)).to eql(ref_id)
          end

          it "has the @module variable" do
            subject
            expect(assigns(:module)).to eql(context_module)
          end

          it "has the @modules variable" do
            subject
            expect(assigns(:modules).length).to be(1)
            expect(assigns(:modules).first).to eql(context_module)
          end

          context "when create_external_apps_side_tray_overrides FF is disabled" do
            before(:once) do
              Account.site_admin.disable_feature!(:create_external_apps_side_tray_overrides)
            end

            it "has the @menu_tools variable" do
              finder_double = double("Lti::ContextToolFinder")
              tool_double_1 = double("Tool 1", has_placement?: true, cache_key: "key")
              tool_double_2 = double("Tool 2", has_placement?: false, cache_key: "key")

              allow_any_instance_of(ContextExternalToolsHelper)
                .to receive(:external_tool_menu_item_tag).and_return("mocked_value")
              allow(Lti::ContextToolFinder)
                .to receive(:new)
                .with(@course, placements: anything, current_user: anything)
                .and_return(finder_double)
              allow(finder_double).to receive(:all_tools_sorted_array).and_return([tool_double_1, tool_double_2])

              subject

              expect(assigns(:menu_tools).values).to all(eq([tool_double_1]))
            end
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
          subject { get "module_html", params: { course_id: @course.id, context_module_id: "random_id" } }

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

        describe "pagination" do
          let(:context_module) do
            context_module = @course.context_modules.create!
            30.times do |i|
              context_module.add_item({ type: "wiki_page", id: page1.id }, nil, position: i)
            end
            context_module
          end

          describe "pagination header" do
            subject do
              super()
              arrays = response.headers["Link"].split(",").map do |row|
                elements = row.split("; ")
                [elements.second.split("=")[1].slice(1..-2), elements.first.slice(1..-2)]
              end
              arrays.to_h
            end

            def expected_page_url(course, context_module, page_number)
              "courses/#{course.id}/modules/#{context_module.id}/items_html?page=#{page_number}&per_page=10"
            end

            it "should return the 'current' page info in the header" do
              subject

              expect(subject["current"]).to end_with(expected_page_url(@course, context_module, 1))
            end

            it "should return the 'next' page info in the header" do
              subject

              expect(subject["next"]).to end_with(expected_page_url(@course, context_module, 2))
            end

            it "should return the 'first' page info in the header" do
              subject

              expect(subject["first"]).to end_with(expected_page_url(@course, context_module, 1))
            end

            it "should return the 'last' page info in the header" do
              subject

              expect(subject["last"]).to end_with(expected_page_url(@course, context_module, 3))
            end
          end

          it "has the default size 10 element @items list" do
            subject

            expect(assigns(:items).length).to be(10)
          end

          context "when change the page size" do
            subject do
              get "items_html", params: {
                course_id: @course.id,
                context_module_id: context_module.id,
                per_page: 5
              }
            end

            it "has the 5 element @items list" do
              subject

              expect(assigns(:items).length).to be(5)
            end
          end

          context "when turning off the pagination" do
            subject do
              get "items_html", params: {
                course_id: @course.id,
                context_module_id: context_module.id,
                no_pagination: true
              }
            end

            it "has the all element @items list" do
              subject

              expect(assigns(:items).length).to be(30)
            end

            it "should not return header with pagination info" do
              subject

              expect(response.headers["Link"]).to be_nil
            end
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

  RSpec.shared_examples "rendering when context_module_id is provided" do
    context "when context_module_id is provided" do
      subject do
        get action, params: { course_id: @course.id, context_module_id: module_id }, format: "json"
        parsed_json
      end

      context "when FF is off" do
        before do
          @course.account.disable_feature!(:modules_perf)
        end

        it "should render unfiltered result" do
          expect(subject).to match_array(expected_full_list)
        end
      end

      context "when FF is on" do
        before do
          @course.account.enable_feature!(:modules_perf)
        end

        context "when provided module id is exist" do
          it "should render filtered result" do
            expect(subject).to match_array(expected_queried_element)
          end
        end

        context "when provided module is is not exist" do
          let(:module_id) { "noop" }

          it "should render 404" do
            expect(subject).to be_empty
            assert_status(404)
          end
        end
      end
    end
  end

  RSpec.shared_examples "rendering when context_module_id is not provided" do
    context "when context_module_id is not provided" do
      subject do
        get action, params: { course_id: @course.id }, format: "json"
        parsed_json
      end

      context "when FF is off" do
        before do
          @course.account.disable_feature!(:modules_perf)
        end

        it "should render unfiltered result" do
          subject

          expect(subject).to match_array(expected_full_list)
        end
      end

      context "when FF is on" do
        before do
          @course.account.enable_feature!(:modules_perf)
        end

        it "should render unfiltered result" do
          subject

          expect(subject).to match_array(expected_full_list)
        end
      end
    end
  end

  describe "filter for module id" do
    let(:module_id) { @module1.id }

    before do
      course_with_teacher_logged_in(active_all: true)
      @assignment = @course.assignments.create!(title: "some assignment", points_possible: 12)
      @module1 = @course.context_modules.create!
      @context_module1_item1 = @module1.add_item({ id: @assignment.id, type: "assignment" })
      @module2 = @course.context_modules.create!
      @context_module2_item1 = @module2.add_item({ id: @assignment.id, type: "assignment" })
    end

    describe "GET assignment_info" do
      let(:action) { "content_tag_assignment_data" }
      let(:parsed_json) { json_parse(response.body).keys }
      let(:expected_full_list) { [@context_module1_item1.id.to_s, @context_module2_item1.id.to_s] }
      let(:expected_queried_element) { [@context_module1_item1.id.to_s] }

      it_behaves_like "rendering when context_module_id is provided"

      it_behaves_like "rendering when context_module_id is not provided"
    end

    describe "GET master_course_info" do
      before do
        @template = MasterCourses::MasterTemplate.set_as_master_course(@course)
        MasterCourses::MasterContentTag.create!(master_template: @template, content: @assignment)
      end

      let(:action) { "content_tag_master_course_data" }
      let(:parsed_json) { json_parse(response.body)["tag_restrictions"].keys }
      let(:expected_full_list) { [@context_module1_item1.id.to_s, @context_module2_item1.id.to_s] }
      let(:expected_queried_element) { [@context_module1_item1.id.to_s] }

      it_behaves_like "rendering when context_module_id is provided"

      it_behaves_like "rendering when context_module_id is not provided"
    end

    describe "GET content_tag_estimated_duration_data" do
      let(:action) { "content_tag_estimated_duration_data" }
      let(:parsed_json) { json_parse(response.body).values.flat_map(&:keys) }
      let(:expected_full_list) { [@context_module1_item1.id.to_s, @context_module2_item1.id.to_s] }
      let(:expected_queried_element) { [@context_module1_item1.id.to_s] }

      it_behaves_like "rendering when context_module_id is provided"

      it_behaves_like "rendering when context_module_id is not provided"
    end

    describe "GET progressions" do
      let(:action) { "progressions" }
      let(:parsed_json) do
        json_parse(response.body).flat_map { |hash| hash["context_module_progression"]["context_module_id"] }
      end
      let(:expected_full_list) { [@module1.id, @module2.id] }
      let(:expected_queried_element) { [@module1.id] }

      before do
        @module1.evaluate_for(@teacher)
        @module2.evaluate_for(@teacher)
      end

      it_behaves_like "rendering when context_module_id is provided"

      it_behaves_like "rendering when context_module_id is not provided"
    end
  end
end
