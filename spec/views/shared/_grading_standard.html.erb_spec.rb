require_relative '../../spec_helper'
require_relative '../views_helper'

describe '/shared/_grading_standard' do

  let(:grading_standard) do
    @course.grading_standards.create!(:title => 'My Grading Standard', :standard_data => {
      :a => {:name => 'A', :value => '95'},
      :b => {:name => 'B', :value => '80'},
      :c => {:name => 'C', :value => '70'},
      :d => {:name => 'D', :value => '60'},
      :f => {:name => 'F', :value => ''}})
  end

  let(:doc) do
    Nokogiri::HTML(response.body)
  end

  before do
    account = Account.default
    @course = Course.create!(name: 'My Course', account: account)
    user = User.create!(name: 'Abby Tabby')
    @course.enroll_user(user, 'TeacherEnrollment')
    user.save!

    view_context(@course, user)
  end

  it 'renders' do
    render partial: 'shared/grading_standard', object: nil, locals: {read_only: false}

    expect(response).not_to be_nil
  end

  it 'does not show find, edit, or remove links when read only' do
    render partial: 'shared/grading_standard', object: nil, locals: {read_only: true}

    expect(doc.css('.find_grading_standard_link').length).to eq 0
    expect(doc.css('.edit_grading_standard_link').length).to eq 0
    expect(doc.css('.remove_grading_standard_link').length).to eq 0
  end

  it 'shows find, edit, and remove links when not read only' do
    render partial: 'shared/grading_standard', object: nil, locals: {read_only: false}

    expect(doc.css('.find_grading_standard_link').length).to eq 1
    expect(doc.css('.edit_grading_standard_link').length).to eq 1
    expect(doc.css('.remove_grading_standard_link').length).to eq 1
  end

  it 'does not show the manage grading schemes link if read only' do
    render partial: 'shared/grading_standard', object: nil, locals: {read_only: true}

    url = context_url(@course, :context_grading_standards_url)

    expect(doc.css("a[href='#{url}']:contains('manage grading schemes')").length).to eq 0
  end

  it 'shows the manage grading schemes link if not read only' do
    render partial: 'shared/grading_standard', object: nil, locals: {read_only: false}

    url = context_url(@course, :context_grading_standards_url)

    expect(doc.css("a[href='#{url}']:contains('manage grading schemes')").length).to eq 1
  end

  it 'displays the proper title for the default grading standard' do
    render partial: 'shared/grading_standard', object: nil, locals: {read_only: false}

    title = GradingStandard.default_instance.title

    expect(doc.css(".title:contains('#{title}')").length).to eq 1
  end

  it 'displays the proper title for a custom grading standard' do
    render partial: 'shared/grading_standard', object: grading_standard, locals: {read_only: false}

    title = grading_standard.title

    expect(doc.css(".title:contains('#{title}')").length).to eq 1
  end

  it 'renders the proper amount of rows for the default grading standard' do
    render partial: 'shared/grading_standard', object: nil, locals: {read_only: false}

    len = GradingStandard.default_instance.data.length

    expect(doc.css('.grading_standard_row:not(.blank)').length).to eq len
  end

  it 'renders the proper amount of rows for a custom grading standard' do
    render partial: 'shared/grading_standard', object: grading_standard, locals: {read_only: false}

    len = grading_standard.data.length

    expect(doc.css('.grading_standard_row:not(.blank)').length).to eq len
  end
end

