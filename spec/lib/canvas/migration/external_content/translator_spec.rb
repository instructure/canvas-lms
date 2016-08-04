require_relative '../../../../spec_helper.rb'

describe Canvas::Migration::ExternalContent::Translator do
  context "#translate_data" do
    before :once do
      @copy_from = course_model
      @quiz = @copy_from.quizzes.create!
      @mig_id = CC::CCHelper.create_key(@quiz)

      @copy_to = course_model
      @quiz_copy = @copy_to.quizzes.new
      @quiz_copy.migration_id = @mig_id
      @quiz_copy.save!

      @cm = @course.content_migrations.create!
      @cm.add_imported_item(@quiz_copy)
      @translator = described_class.new(@cm)
    end

    it "should search through arrays" do
      data = [
        {'something' => 'somethingelse'},
        {'$canvas_quiz_id' => @quiz.id}
      ]
      exported_data = @translator.translate_data(data, :export)
      expect(exported_data.last['$canvas_quiz_id']).to eq @mig_id

      imported_data = @translator.translate_data(exported_data, :import)
      expect(imported_data.last['$canvas_quiz_id']).to eq @quiz_copy.id
    end

    it "should search through nested hashes" do
      data = {'key' => {'$canvas_quiz_id' => @quiz.id}}
      exported_data = @translator.translate_data(data, :export)
      expect(exported_data['key']['$canvas_quiz_id']).to eq @mig_id

      imported_data = @translator.translate_data(exported_data, :import)
      expect(imported_data['key']['$canvas_quiz_id']).to eq @quiz_copy.id
    end
  end

  context "#get_canvas_id_from_migration_id" do
    before :once do
      course_model
      @cm = @course.content_migrations.create!
      @translator = described_class.new(@cm)
    end

    it "should be able to search for all of the types in the course" do
      # make sure none of the types asplode the fallback logic
      described_class::TYPES_TO_CLASSES.values.each do |obj_class|
        expect(@translator.get_canvas_id_from_migration_id(obj_class, "some_migration_id")).to eq described_class::NOT_FOUND
      end
    end

    it "should be able to find an already imported item" do
      mig_id = "somemigrationid"
      assmt = @course.assignments.new
      assmt.migration_id = mig_id
      assmt.save!

      expect(@translator.get_canvas_id_from_migration_id(Assignment, mig_id)).to eq assmt.id
    end

    it "should search through recently imported items first" do
      mig_id = "somemigrationid"
      assmt = @course.assignments.new
      assmt.migration_id = mig_id
      assmt.save!
      @cm.add_imported_item(assmt)

      @course.expects(:assignments).never
      expect(@translator.get_canvas_id_from_migration_id(Assignment, mig_id)).to eq assmt.id
    end
  end
end