require_relative '../../helpers/gradezilla_common'
require_relative '../page_objects/gradezilla_page'

describe "Gradezilla" do
  include_context "in-process server selenium tests"
  include GradezillaCommon

  let(:gradezilla_page) { Gradezilla::MultipleGradingPeriods.new }

  before(:once) do
    gradebook_data_setup
    @page_size = 5
    Setting.set 'api_max_per_page', @page_size
  end

  before do
    user_session(@teacher)
  end

  def test_n_students(n)
    create_users_in_course @course, n
    gradezilla_page.visit(@course)
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
