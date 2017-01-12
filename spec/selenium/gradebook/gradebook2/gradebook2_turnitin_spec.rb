require_relative '../../helpers/gradebook2_common'

describe "gradebook2 - turnitin" do
  include_context "in-process server selenium tests"
  include Gradebook2Common

  let!(:setup) { gradebook_data_setup }

  it "should show turnitin data" do
    s1 = @first_assignment.submit_homework(@student_1, :submission_type => 'online_text_entry', :body => 'asdf')
    s1.update_attribute :turnitin_data, {
      "submission_#{s1.id}" => {
        :similarity_score => 0.0,
        :web_overlap => 0.0,
        :publication_overlap => 0.0,
        :student_overlap => 0.0,
        :state => 'none'
      }
    }
    a = attachment_model(:context => @student_2, :content_type => 'text/plain')
    s2 = @first_assignment.submit_homework(@student_2, :submission_type => 'online_upload', :attachments => [a])
    s2.update_attribute :turnitin_data, {
      "attachment_#{a.id}" => {
        :similarity_score => 1.0,
        :web_overlap => 5.0,
        :publication_overlap => 0.0,
        :student_overlap => 0.0,
        :state => 'acceptable'
      }
    }

    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    icons = ffj('.gradebook-cell-turnitin')
    expect(icons.size).to eq 2

    none        = ffj('.none-score')[0]       # icons[0]
    acceptable  = ffj('.acceptable-score')[0] # icons[1]
    # make sure it appears in each submission dialog

    cell = none.find_element(:xpath, '..')

    driver.action.move_to(f('#gradebook_settings')).move_to(cell).perform
    expect(cell.find_element(:css, "a")).to be_displayed
    cell.find_element(:css, "a").click
    wait_for_ajaximations

    fj('.ui-icon-closethick:visible').click

    cell = acceptable.find_element(:xpath, '..')

    # This is a quick fix to change the keyboard focus so that an accessible
    # tooltip does not block the visibility of the cell.
    driver.action.send_keys(:tab).perform
    driver.action.move_to(f('#gradebook_settings')).move_to(cell).perform
    expect(cell.find_element(:css, "a")).to be_displayed
    cell.find_element(:css, "a").click
    wait_for_ajaximations

    fj('.ui-icon-closethick:visible').click

  end
end
