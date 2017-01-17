require File.expand_path(File.dirname(__FILE__) + '/../../common')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/grading_schemes_common')

describe "sub account grading schemes" do
  include_context "in-process server selenium tests"
  include GradingSchemesCommon

  let(:account) { Account.create(:name => 'sub account from default account', :parent_account => Account.default) }
  let(:url) { "/accounts/#{account.id}/grading_standards" }

  before do
    course_with_admin_logged_in
    get url
    f('#react_grading_tabs a[href="#grading-standards-tab"]').click
  end

  describe "grading schemes" do
    it "should add a grading scheme", priority: "1", test_id: 238155 do
      should_add_a_grading_scheme
    end

    it "should edit a grading scheme", priority: "1", test_id: 238156 do
      should_edit_a_grading_scheme(account, url)
    end

    it "should delete a grading scheme", priority: "1", test_id: 238160 do
      should_delete_a_grading_scheme(account, url)
    end

    it 'should disable add grading scheme button during update', priority: "2", test_id: 164232 do
      simple_grading_standard(account)
      get url
      f('#react_grading_tabs a[href="#grading-standards-tab"]').click
      f('.edit_grading_standard_button').click
      expect(f('#react_grading_tabs .add_standard_button')).to have_class('disabled')
    end

    it 'should disable other grading schemes from being edited', priority: "2", test_id: 307626 do
      2.times do
        simple_grading_standard(account)
      end
      get url
      f('#react_grading_tabs a[href="#grading-standards-tab"]').click
      f('.edit_grading_standard_button').click
      expect(f('.disabled-buttons')).to be_truthy
    end

    it 'should allow all available grading schemes to be edited on page load', priority: "2", test_id: 310145 do
      2.times do
        simple_grading_standard(account)
      end
      get url
      f('#react_grading_tabs a[href="#grading-standards-tab"]').click
      expect(ff('.standard_title .links').count).to eq(2)
    end
  end

  describe "grading scheme items" do
    before do
      create_simple_standard_and_edit(account, url)
    end

    it "should add a grading scheme item", priority: "1", test_id: 238157 do
      should_add_a_grading_scheme_item
    end

    it "should edit a grading scheme item", priority: "1", test_id: 238158 do
      should_edit_a_grading_scheme_item
    end

    it "should delete a grading scheme item", priority: "1", test_id: 238159 do
      should_delete_a_grading_scheme_item
    end

    it "should not update when invalid scheme input is given", priority: "1", test_id: 238162 do
      should_not_update_invalid_grading_scheme_input
    end
  end
end
