require File.expand_path(File.dirname(__FILE__) + '/helpers/gradebook2_common')

describe "outcome gradebook" do
  include_context "in-process server selenium tests"

  context "as a teacher" do
    before(:each) do
      gradebook_data_setup
    end

    it "should not be visible by default" do
      get "/courses/#{@course.id}/gradebook2"
      expect(ff('.gradebook-navigation').length).to eq 0
    end

    context "when enabled" do
      before :once do
        Account.default.set_feature_flag!('outcome_gradebook', 'on')
      end

      it "should be visible" do
        get "/courses/#{@course.id}/gradebook2"
        expect(ff('.gradebook-navigation').length).to eq 1

        f('a[data-id=outcome]').click
        wait_for_ajaximations
        expect(f('.outcome-gradebook-container')).not_to be_nil
      end

      it "should allow showing only a certain section" do
        get "/courses/#{@course.id}/gradebook2"
        f('a[data-id=outcome]').click
        wait_for_ajaximations

        expect(ff('.outcome-student-cell-content').length).to eq 3

        choose_section = ->(name) do
          fj('.section-select-button:visible').click
          wait_for_js
          ffj('.section-select-menu:visible a').find { |a| a.text.include? name }.click
          wait_for_js
        end

        choose_section.call "All Sections"
        expect(fj('.section-select-button:visible')).to include_text("All Sections")

        choose_section.call @other_section.name
        expect(fj('.section-select-button:visible')).to include_text(@other_section.name)

        expect(ff('.outcome-student-cell-content').length).to eq 1

        # verify that it remembers the section to show across page loads
        get "/courses/#{@course.id}/gradebook2"
        expect(fj('.section-select-button:visible')).to include_text @other_section.name
        expect(ff('.outcome-student-cell-content').length).to eq 1

        # now verify that you can set it back

        fj('.section-select-button:visible').click
        wait_for_ajaximations
        keep_trying_until { expect(fj('.section-select-menu:visible')).to be_displayed }
        fj("label[for='section_option_#{''}']").click
        keep_trying_until { expect(fj('.section-select-button:visible')).to include_text "All Sections" }

        expect(ff('.outcome-student-cell-content').length).to eq 3
      end

      it "should handle multiple enrollments correctly" do
        @course.enroll_student(@student_1, :section => @other_section, :allow_multiple_enrollments => true)

        get "/courses/#{@course.id}/gradebook2"
        wait_for_ajaximations

        meta_cells = find_slick_cells(0, f('.grid-canvas'))
        expect(meta_cells[0]).to include_text @course.default_section.display_name
        expect(meta_cells[0]).to include_text @other_section.display_name

        switch_to_section(@course.default_section)
        meta_cells = find_slick_cells(0, f('.grid-canvas'))
        expect(meta_cells[0]).to include_text @student_name_1

        switch_to_section(@other_section)
        meta_cells = find_slick_cells(0, f('.grid-canvas'))
        expect(meta_cells[0]).to include_text @student_name_1
      end
    end
  end
end