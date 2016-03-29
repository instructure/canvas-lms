require_relative '../../helpers/gradebook2_common'

describe "gradebook2" do
  include_context "in-process server selenium tests"
  include Gradebook2Common

  let!(:setup) { gradebook_data_setup }

  before do
    @page_size = 5
    Setting.set 'api_max_per_page', @page_size
  end

  def test_n_students(n)
    n.times { |i| student_in_course(:name => "student #{i+1}") }
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    f('.gradebook_filter input').send_keys n
    sleep 1 # InputFilter has a delay
    expect(ff('.student-name').size).to eq 1
    expect(f('.student-name').text).to eq "student #{n}"
  end

  it "should work for 2 pages" do
    test_n_students @page_size + 1
  end

  it "should work for >2 pages" do
    test_n_students @page_size * 2 + 1
  end
end
