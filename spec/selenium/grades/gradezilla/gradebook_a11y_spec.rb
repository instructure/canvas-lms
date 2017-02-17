require_relative '../../helpers/gradezilla_common'
require_relative '../page_objects/gradezilla_page'

describe "Gradezilla" do
  include_context "in-process server selenium tests"
  include GradezillaCommon

  let(:gradezilla_page) { Gradezilla::MultipleGradingPeriods.new }

  let(:extra_setup) { }
  let(:active_element) { driver.switch_to.active_element }

  before(:once) do
    gradebook_data_setup
  end

  before do
    Account.default.set_feature_flag!('gradezilla', 'on')
    extra_setup
    user_session(@teacher)
    gradezilla_page.visit(@course)
  end

  context "export menu" do
    before { f('span[data-component="ActionMenu"] button').click }

    it "moves focus to Actions menu trigger button during current export", priority: "2", test_id: 720459 do
      f('span[data-menu-id="export"]').click

      expect(active_element.tag_name).to eq('button')
      expect(active_element.text).to eq('Actions')
    end

    context "when a csv already exists" do
      let(:extra_setup) do
        attachment = @course.attachments.create!(uploaded_data: default_uploaded_data)
        progress = @course.progresses.new(tag: 'gradebook_export')
        progress.workflow_state = 'completed'
        progress.save!
        @course.gradebook_csvs.create!(user: @teacher,
                                       progress: progress,
                                       attachment: attachment)
      end

      it "maintains focus to Actions menu trigger during past csv export", priority: "2", test_id: 720460 do
        f('span[data-menu-id="previous-export"]').click

        expect(active_element.tag_name).to eq('button')
        expect(active_element.text).to eq('Actions')
      end
    end
  end

  context "return focus to settings menu when it closes" do
    before { f('#gradebook_settings').click }

    it "after hide/show student names is clicked", priority: "2", test_id: 720461 do
      f(".student_names_toggle").click
      expect(active_element).to have_attribute('id', 'gradebook_settings')
    end

    it "after arrange columns is clicked", priority: "2", test_id: 720462 do
      f("[data-arrange-columns-by='due_date']").click
      expect(active_element).to have_attribute('id', 'gradebook_settings')
    end

    it "after show notes is clicked", priority: "2", test_id: 720463 do
      f('.create').click
      expect(active_element).to have_attribute('id', 'gradebook_settings')
    end
  end
end
