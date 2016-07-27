require_relative '../../helpers/gradebook2_common'
require_relative '../../helpers/groups_common'

describe "gradebook2" do
  include_context "in-process server selenium tests"
  include Gradebook2Common
  include GroupsCommon

  let!(:setup) { gradebook_data_setup }

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

  it "should allow showing only a certain section", priority: "1", test_id: 210024 do
    get "/courses/#{@course.id}/gradebook2"
    # grade the first assignment
    edit_grade('#gradebook_grid .container_1 .slick-row:nth-child(1) .l2', 0)
    edit_grade('#gradebook_grid .container_1 .slick-row:nth-child(2) .l2', 1)

    switch_to_section(@other_section)
    expect(fj('.section-select-button:visible')).to include_text(@other_section.name)

    expect(f('#gradebook_grid .container_1 .slick-row:nth-child(1) .l2').text).to eq '1'

    # verify that it remembers the section to show across page loads
    get "/courses/#{@course.id}/gradebook2"
    expect(fj('.section-select-button:visible')).to include_text @other_section.name
    expect(f('#gradebook_grid .container_1 .slick-row:nth-child(1) .l2').text).to eq '1'

    # now verify that you can set it back

    fj('.section-select-button:visible').click
    expect(fj('.section-select-menu:visible')).to be_displayed
    f("label[for='section_option_']").click
    expect(fj('.section-select-button:visible')).to include_text "All Sections"

    # validate all grades (i.e. submissions) were loaded
    expect(f('#gradebook_grid .container_1 .slick-row:nth-child(1) .l2').text).to eq '0'
    expect(f('#gradebook_grid .container_1 .slick-row:nth-child(2) .l2').text).to eq '1'
  end
end
