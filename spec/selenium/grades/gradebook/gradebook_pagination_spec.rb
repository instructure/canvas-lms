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
    create_users_in_course @course, n
    get "/courses/#{@course.id}/gradebook2"
    f('.gradebook_filter input').send_keys n
    expect(ff('.student-name')).to have_size 1
    expect(f('.student-name')).to include_text "user #{n}"
  end

  it "should work for 2 pages" do
    test_n_students @page_size + 1
  end

  it "should work for >2 pages" do
    test_n_students @page_size * 2 + 1
  end
end
