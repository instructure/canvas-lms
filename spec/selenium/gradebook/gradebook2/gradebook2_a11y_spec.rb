require_relative '../../helpers/gradebook2_common'

describe "gradebook2" do
  include_context "in-process server selenium tests"
  include Gradebook2Common

  let!(:setup) { gradebook_data_setup }
  let!(:navigate_to_the_gradebook) { get "/courses/#{@course.id}/gradebook2" }

  let(:active_element) { driver.execute_script('return document.activeElement') }

  context "export menu" do
    let!(:open_gradebook_export_menu) { f('#download_csv').click }

    it "moves focus to import button during current export", priority: "2", test_id: 720459 do
      f('.generate_new_csv').click

      expect(active_element).to have_class('ui-button')
    end

    context "when a csv already exists" do
      let!(:setup) do
        gradebook_data_setup

        attachment = @course.attachments.create!(
          uploaded_data: default_uploaded_data
        )
        progress = @course.progresses.new(tag: 'gradebook_export')
        progress.workflow_state = 'completed'
        progress.save!
        @course.gradebook_csvs.create!(
          user: @teacher,
          progress: progress,
          attachment: attachment
        )
      end

      it "maintains focus on export button during past csv export", priority: "2", test_id: 720460 do
        wait_for_ajaximations
        f('#csv_export_options .ui-menu-item:not(.generate_new_csv)').click

        expect(active_element).to have_attribute('id', 'download_csv')
      end
    end
  end

  context "return focus to settings menu when it closes" do
    let!(:open_gradebook_settings_menu) { f('#gradebook_settings').click }

    it "after set group weights closes", priority: "2", test_id: 720464 do
      f("[aria-controls='assignment_group_weights_dialog']").click
      f('.ui-dialog-titlebar-close').click

      expect(active_element).to have_attribute('id', 'gradebook_settings')
    end

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
