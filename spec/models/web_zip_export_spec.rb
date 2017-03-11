require 'spec_helper'

describe WebZipExport do
  before :once do
    course_with_student(active_all: true)
  end

  describe "#generate" do
    let_once(:web_zip_export) do
      @course.web_zip_exports.create({
        user: @student
      }).tap do |web_zip_export|
        web_zip_export.update_attribute(:workflow_state, 'exported')
      end
    end

    it "should update job_progress completion" do
      web_zip_export.generate_without_send_later
      expect(web_zip_export.job_progress.completion).to eq WebZipExport::PERCENTAGE_COMPLETE[:generating]
    end

    it "should set state to generating" do
      web_zip_export.generate_without_send_later
      expect(web_zip_export.generating?).to be_truthy
    end

    it 'should create and associate an attachment' do
      web_zip_export.export_without_send_later
      web_zip_export.content_export.export_without_send_later
      expect(web_zip_export.zip_attachment).to be_nil, 'precondition'
      dist_folder = 'node_modules/canvas_offline_course_viewer/dist'
      expect_any_instance_of(CC::Exporter::WebZip::ZipPackage).to receive(:add_dir_to_zip).with(dist_folder, dist_folder)
      expect{web_zip_export.convert_to_offline_web_zip_without_send_later}.to change{Attachment.count}.by(1)
      web_zip_export.reload
      expect(web_zip_export.zip_attachment).not_to be_nil
    end
  end

  describe '#export' do
    before do
      enable_cache
      @web_zip_export = @course.web_zip_exports.create(user: @student, workflow_state: 'created')
    end

    it "should cache user module progress" do
      modul = @course.context_modules.create!(name: 'first_module')
      assign = @course.assignments.create!(title: 'Assignment 1')
      assign_item = modul.content_tags.create!(content: assign, context: @course)
      modul.completion_requirements = [{id: assign_item.id, type: 'must_submit'}]
      modul.save!
      @web_zip_export.export_without_send_later
      progress = Rails.cache.fetch("web_zip_export_user_progress_#{@web_zip_export.global_id}")
      expect(progress).to eq({modul.id => {status: 'unlocked', items: {assign_item.id => false}}})
    end
  end
end
