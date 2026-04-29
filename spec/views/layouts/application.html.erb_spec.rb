# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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
describe "layouts/application" do
  before do
    @current_user = user_factory
    assign(:current_user, @current_user)
    assign(:domain_root_account, Account.default)
  end

  def doc
    Nokogiri::HTML5(response.body)
  end

  it "renders" do
    render "layouts/application"
    expect(doc.at_css(".ic-app.content-only")).to be_nil
  end

  context "with content_only=true" do
    before do
      allow(controller).to receive(:params).and_return({ content_only: "true" })
    end

    it "adds content-only class to application" do
      render "layouts/application"
      expect(doc.at_css(".ic-app.content-only")).to be_present
    end

    it "renders the flash notices partial" do
      render "layouts/application"
      expect(doc.at_css("#flash_message_holder")).to be_present
    end
  end

  context "with hide_global_nav=true" do
    before do
      allow(controller).to receive(:params).and_return({ hide_global_nav: "true" })
    end

    it "adds hide-global-nav class to body" do
      render "layouts/application"
      expect(doc.at_css("body.hide-global-nav")).to be_present
    end

    it "still renders the navigation header partial (CSS will hide elements)" do
      render "layouts/application"
      # The header should be rendered in HTML (CSS will selectively hide elements)
      expect(doc.at_css("header#header.ic-app-header")).to be_present
    end

    it "still renders breadcrumbs (unlike content_only)" do
      @context = course_factory
      assign(:context, @context)
      allow(view).to receive_messages(
        crumbs: [["Home", "/"], ["Courses", "/courses"]],
        render_crumbs: "<a href='/'>Home</a>".html_safe
      )
      render "layouts/application"
      expect(doc.at_css(".ic-app-nav-toggle-and-crumbs")).to be_present
    end
  end

  context "with @show_footer" do
    it "shows footer when true" do
      assign(:show_footer, true)
      render "layouts/application"
      expect(doc.at_css("#footer.ic-app-footer")).to be_present
    end

    it "hides footer when false" do
      assign(:show_footer, false)
      render "layouts/application"
      expect(doc.at_css("#footer")).to be_nil
    end

    it "hides footer when content_only=true regardless of @show_footer" do
      assign(:show_footer, true)
      allow(controller).to receive(:params).and_return({ content_only: "true" })
      render "layouts/application"
      expect(doc.at_css("#footer")).to be_nil
    end
  end

  context "with @instui_topnav" do
    it "shows topnav when true" do
      assign(:instui_topnav, true)
      render "layouts/application"
      container = doc.at_css(".instui-topnav-container")
      expect(container).to be_present
      expect(container.at_css("#react-instui-topnav")).to be_present
    end

    it "hides topnav when false" do
      assign(:instui_topnav, false)
      render "layouts/application"
      expect(doc.at_css(".instui-topnav-container")).to be_nil
    end

    it "hides topnav when content_only=true regardless of @instui_topnav" do
      assign(:instui_topnav, true)
      allow(controller).to receive(:params).and_return({ content_only: "true" })
      render "layouts/application"
      expect(doc.at_css(".instui-topnav-container")).to be_nil
    end

    context "with crumbs" do
      before do
        assign(:instui_topnav, false)
        @context = course_factory
        assign(:context, @context)

        # Mock crumbs.length to show the navigation container
        crumbs_html = "<a href='/'>Home</a><a href='/courses'>Courses</a>"
        # rubocop:disable Rails/OutputSafety
        allow(view).to receive_messages(
          crumbs: [["Home", "/"], ["Courses", "/courses"]],
          render_crumbs: crumbs_html.html_safe
        )
        # rubocop:enable Rails/OutputSafety
      end

      it "shows crumbs when topnav is disabled" do
        render "layouts/application"
        nav = doc.at_css(".ic-app-nav-toggle-and-crumbs")
        expect(nav).to be_present

        crumbs_div = nav.at_css(".ic-app-crumbs")
        expect(crumbs_div).to be_present
      end

      it "hides crumbs when content_only=true" do
        allow(controller).to receive(:params).and_return({ content_only: "true" })
        render "layouts/application"
        expect(doc.at_css(".ic-app-nav-toggle-and-crumbs")).to be_nil
      end

      context "with right-of-crumbs elements" do
        before do
          @context = course_factory
          assign(:context, @context)
          assign(:domain_root_account, Account.default)
        end

        context "top navigation accessibility order" do
          it "adds right-of-crumbs-no-reverse class" do
            render "layouts/application"
            right_of_crumbs = doc.at_css(".right-of-crumbs")
            expect(right_of_crumbs).to be_present
            expect(right_of_crumbs["class"]).to include("right-of-crumbs-no-reverse")
          end

          it "renders elements in logical left-to-right order (observer picker first)" do
            student_in_course(active_all: true, course: @context)
            observer = user_factory
            @context.enroll_user(observer, "ObserverEnrollment", enrollment_state: "active", associated_user_id: @student.id)
            assign(:current_user, observer)
            assign(:context_enrollment, @context.enrollments.where(user_id: observer.id).first)
            render "layouts/application"

            right_of_crumbs = doc.at_css(".right-of-crumbs")
            children = right_of_crumbs.children.select(&:element?)
            # First element should be observer picker when present
            expect(children.first["id"]).to eq("observer-picker-mountpoint")
          end

          it "renders student view button before top-nav-tools when present" do
            Account.default.enable_feature!(:top_navigation_placement)
            course_with_teacher_logged_in(active_all: true, course: @context)
            assign(:current_user, @teacher)
            render "layouts/application"

            right_of_crumbs = doc.at_css(".right-of-crumbs")
            children = right_of_crumbs.children.select(&:element?)
            children_ids = children.pluck("id").compact

            student_view_index = children_ids.index("easy_student_view")
            top_nav_tools_index = children_ids.index("top-nav-tools-mount-point")

            expect(student_view_index).to be < top_nav_tools_index if student_view_index && top_nav_tools_index
          end

          it "renders ai-information last" do
            render "layouts/application"
            right_of_crumbs = doc.at_css(".right-of-crumbs")
            children = right_of_crumbs.children.select(&:element?)
            # Last element should be ai-information-mount
            expect(children.last["id"]).to eq("ai-information-mount")
          end
        end

        context "with top_navigation_placement feature" do
          it "renders top-nav-tools-mount-point when feature is enabled on domain root account" do
            Account.default.enable_feature!(:top_navigation_placement)
            render "layouts/application"
            expect(doc.at_css("#top-nav-tools-mount-point")).to be_present
          end
        end

        context "with student view button" do
          before do
            course_with_teacher_logged_in(active_all: true, course: @context)
            assign(:current_user, @teacher)
            allow(view).to receive_messages(show_student_view_button?: true, student_view_text: "Student View")
          end

          it "renders student view button when helper returns true" do
            render "layouts/application"
            student_view_link = doc.at_css("#easy_student_view")
            expect(student_view_link).to be_present
            expect(student_view_link.text.strip).to include("View as Student")
          end

          it "has correct attributes for student view button" do
            render "layouts/application"
            student_view_link = doc.at_css("#easy_student_view")
            expect(student_view_link["class"]).to include("btn btn-top-nav")
            expect(student_view_link["aria-label"]).to be_present
            expect(student_view_link["data-method"]).to eq("post")
          end

          it "does not render when helper returns false" do
            allow(view).to receive(:show_student_view_button?).and_return(false)
            render "layouts/application"
            expect(doc.at_css("#easy_student_view")).to be_nil
          end
        end

        context "with observer picker" do
          it "renders observer picker for observers in course context" do
            student_in_course(active_all: true, course: @context)
            observer = user_factory
            enrollment = @context.enroll_user(observer, "ObserverEnrollment", enrollment_state: "active", associated_user_id: @student.id)
            assign(:current_user, observer)
            assign(:context_enrollment, enrollment)
            render "layouts/application"
            expect(doc.at_css("#observer-picker-mountpoint")).to be_present
          end

          it "renders observer picker for observers in assignment context" do
            student_in_course(active_all: true, course: @context)
            observer = user_factory
            enrollment = @context.enroll_user(observer, "ObserverEnrollment", enrollment_state: "active", associated_user_id: @student.id)
            assignment = @context.assignments.create!(title: "Test Assignment")
            assign(:context, assignment)
            assign(:current_user, observer)
            assign(:context_enrollment, enrollment)
            render "layouts/application"
            expect(doc.at_css("#observer-picker-mountpoint")).to be_present
          end

          it "does not render observer picker for non-observers" do
            course_with_teacher_logged_in(active_all: true, course: @context)
            assign(:current_user, @teacher)
            assign(:context_enrollment, @context.enrollments.where(user_id: @teacher.id).first)
            render "layouts/application"
            expect(doc.at_css("#observer-picker-mountpoint")).to be_nil
          end
        end

        context "with top navigation tools and a11y fixes" do
          let(:tool) do
            @context.context_external_tools.create!(
              name: "Test LTI Tool",
              consumer_key: "key",
              shared_secret: "secret",
              url: "http://example.com/launch",
              settings: { top_navigation: {} }
            )
          end

          before do
            Account.default.enable_feature!(:top_navigation_placement)
            course_with_teacher_logged_in(active_all: true, course: @context)
            assign(:current_user, @teacher)
            tool # create the tool
          end

          context "with student view button" do
            before do
              allow(view).to receive_messages(show_student_view_button?: true, student_view_text: "View as Student")
            end

            it "renders student view button before top-nav-tools-mount-point" do
              render "layouts/application"

              right_of_crumbs = doc.at_css(".right-of-crumbs")
              children = right_of_crumbs.children.select(&:element?)
              children_ids = children.pluck("id").compact

              student_view_index = children_ids.index("easy_student_view")
              top_nav_tools_index = children_ids.index("top-nav-tools-mount-point")

              expect(student_view_index).to be_present
              expect(top_nav_tools_index).to be_present
              expect(student_view_index).to be < top_nav_tools_index
            end

            it "maintains visual order with logical DOM order" do
              render "layouts/application"

              right_of_crumbs = doc.at_css(".right-of-crumbs")
              children = right_of_crumbs.children.select(&:element?)
              children_ids = children.pluck("id").compact

              # Expected order: observer-picker (if any), student-view, top-nav-tools,
              # immersive-reader (if any), tutorials (if any), ai-information
              student_view_index = children_ids.index("easy_student_view")
              top_nav_tools_index = children_ids.index("top-nav-tools-mount-point")
              ai_info_index = children_ids.index("ai-information-mount")

              expect(student_view_index).to be < top_nav_tools_index
              expect(top_nav_tools_index).to be < ai_info_index
            end
          end
        end
      end
    end
  end
end
