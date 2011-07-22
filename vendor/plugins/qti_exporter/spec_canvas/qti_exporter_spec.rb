require File.expand_path(File.dirname(__FILE__) + '/../../../../spec/spec_helper')

if Qti.migration_executable

describe 'QtiExporter' do
  it "should import duplicate files once, without munging" do
    fname = File.expand_path("../fixtures/spec-canvas-1.zip", __FILE__)
    course_with_teacher(:active_all => true)
    migration = ContentMigration.new(:context => @course,
                                     :user => @user)
    migration.update_migration_settings({
      :migration_type => 'qti_exporter',
    })
    migration.save!

    attachment = Attachment.new
    attachment.context = migration
    attachment.uploaded_data = File.open(fname, 'rb')
    attachment.filename = 'qti_import_test1.zip'
    attachment.save!

    migration.attachment = attachment
    migration.save!
    Canvas::MigrationWorker::QtiWorker.new(migration.id).perform
    migration.reload
    migration.import_content_without_send_later

    @course.attachments.count.should == 1
    attachment = @course.attachments.last
    attachment.filename.should == 'header-logo.png'
    quiz = @course.quizzes.last
    quiz.should be_present
    quiz.quiz_questions.count.should == 2
    quiz.quiz_questions.each do |q|
      text = Nokogiri::HTML::DocumentFragment.parse(q.question_data['question_text'])
      text.css('img').first['src'].should == "/courses/#{@course.id}/files/#{attachment.id}/preview"
    end
  end
end

end
