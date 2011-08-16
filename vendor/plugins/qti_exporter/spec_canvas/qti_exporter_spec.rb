require File.expand_path(File.dirname(__FILE__) + '/../../../../spec/spec_helper')
require 'zip/zipfilesystem'

if Qti.migration_executable

describe 'QtiExporter' do
  before do
    course_with_teacher(:active_all => true)
  end

  it "should import duplicate files once, without munging" do
    setup_migration
    do_migration

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
    quiz.assignment.should be_nil
  end

  it "should publish as assignment on import if specified" do
    copy = Tempfile.new(['spec-canvas', '.zip'])
    FileUtils.cp(fname, copy.path)
    Zip::ZipFile.open(copy.path) do |zf|
      zf.file.open("settings.xml", 'w') do |f|
        f.write <<-XML
        <settings>
          <setting name='hasSettings'>true</setting>
          <setting name='publishNow'>true</setting>
        </settings>
        XML
      end
    end
    setup_migration(copy.path)
    @migration.update_migration_settings(:apply_respondus_settings_file => true)
    @migration.save!
    do_migration

    quiz = @course.quizzes.last
    quiz.should be_present
    quiz.assignment.should_not be_nil
    quiz.assignment.title.should == quiz.title
    quiz.assignment.should be_published
  end

  it "should re-use the same assignment on update" do
    copy = Tempfile.new(['spec-canvas', '.zip'])
    FileUtils.cp(fname, copy.path)
    Zip::ZipFile.open(copy.path) do |zf|
      zf.file.open("settings.xml", 'w') do |f|
        f.write <<-XML
        <settings>
          <setting name='hasSettings'>true</setting>
          <setting name='publishNow'>true</setting>
        </settings>
        XML
      end
    end
    setup_migration(copy.path)
    @migration.update_migration_settings(:apply_respondus_settings_file => true)
    @migration.save!
    do_migration

    setup_migration(copy.path)
    @migration.update_migration_settings(:apply_respondus_settings_file => true, :quiz_id_to_update => @course.quizzes.last.id)
    @migration.save!
    do_migration

    @course.quizzes.size.should == 1
    @course.assignments.size.should == 1
    quiz = @course.quizzes.last
    quiz.should be_present
    quiz.assignment.should_not be_nil
    quiz.assignment.title.should == quiz.title
    quiz.assignment.should be_published
  end

  it "should publish spec-canvas-1 correctly" do
    setup_migration
    do_migration

    quiz = @course.quizzes.last
    quiz.should be_present
    quiz.quiz_questions.size.should == 2
    # various checks on the data
    qq = quiz.quiz_questions.first
    d = qq.question_data
    d['correct_comments'].should == "I can't believe you got that right. Awesome!"
    d['correct_comments_html'].should == "I can't <i>believe </i>you got that right. <b>Awesome!</b>"
    d['points_possible'].should == 3
    d['question_name'].should == 'q1'
    d['answers'].map { |a| a['weight'] }.should == [0,100,0]
  end

  def fname
    File.expand_path("../fixtures/spec-canvas-1.zip", __FILE__)
  end

  def setup_migration(zip_path = fname)
    @migration = ContentMigration.new(:context => @course,
                                     :user => @user)
    @migration.update_migration_settings({
      :migration_type => 'qti_exporter',
    })
    @migration.save!

    @attachment = Attachment.new
    @attachment.context = @migration
    @attachment.uploaded_data = File.open(zip_path, 'rb')
    @attachment.filename = 'qti_import_test1.zip'
    @attachment.save!

    @migration.attachment = @attachment
    @migration.save!
  end

  def do_migration
    Canvas::MigrationWorker::QtiWorker.new(@migration.id).perform
    @migration.reload
    @migration.import_content_without_send_later
    @migration.should be_imported
  end
end

end
