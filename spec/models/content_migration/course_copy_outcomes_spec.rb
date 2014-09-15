require File.expand_path(File.dirname(__FILE__) + '/course_copy_helper.rb')

describe ContentMigration do
  context "course copy outcomes" do
    include_examples "course copy"

    it "should copy all learning outcomes and their groups if selected" do
      default = @copy_from.root_outcome_group
      log = @copy_from.learning_outcome_groups.new
      log.context = @copy_from
      log.title = "outcome group"
      log.description = "<p>Groupage</p>"
      log.save!
      default.adopt_outcome_group(log)

      lo = @copy_from.created_learning_outcomes.new
      lo.context = @copy_from
      lo.short_description = "outcome1"
      lo.workflow_state = 'active'
      lo.data = {:rubric_criterion=>{:mastery_points=>2, :ratings=>[{:description=>"e", :points=>50}, {:description=>"me", :points=>2}, {:description=>"Does Not Meet Expectations", :points=>0.5}], :description=>"First outcome", :points_possible=>5}}
      lo.save!

      log.add_outcome(lo)

      @cm.copy_options = {
          :all_learning_outcomes => "1"
      }
      @cm.save!

      run_course_copy

      @copy_to.created_learning_outcomes.find_by_migration_id(mig_id(lo)).should_not be_nil
      @copy_to.learning_outcome_groups.find_by_migration_id(mig_id(log)).should_not be_nil
    end

    it "should copy learning outcome alignments with question banks" do
      pending unless Qti.qti_enabled?
      default = @copy_from.root_outcome_group
      lo = @copy_from.created_learning_outcomes.new
      lo.context = @copy_from
      lo.short_description = "outcome1"
      lo.workflow_state = 'active'
      lo.data = {:rubric_criterion=>{:mastery_points=>2, :ratings=>[{:description=>"e", :points=>50}, {:description=>"me", :points=>2}, {:description=>"Does Not Meet Expectations", :points=>0.5}], :description=>"First outcome", :points_possible=>5}}
      lo.save!
      default.add_outcome(lo)

      bank = @copy_from.assessment_question_banks.create!(:title => 'bank')
      bank.assessment_questions.create!(:question_data => {'name' => 'test question', 'answers' => [{'id' => 1}, {'id' => 2}]})

      lo.align(bank, @copy_from, {:mastery_type => 'points', :mastery_score => 50.0})

      run_course_copy

      new_lo = @copy_to.learning_outcomes.find_by_migration_id(mig_id(lo))
      new_bank = @copy_to.assessment_question_banks.find_by_migration_id(mig_id(bank))

      new_lo.alignments.count.should == 1
      new_alignment = new_lo.alignments.first

      new_alignment.content.should == new_bank
      new_alignment.context.should == @copy_to

      new_alignment.tag.should == 'points_mastery'
      new_alignment.mastery_score.should == 50.0
    end

    it "should copy learning outcomes into the new course" do
      old_root = @copy_from.root_outcome_group

      lo = create_outcome(@copy_from, old_root)

      log = @copy_from.learning_outcome_groups.new
      log.context = @copy_from
      log.title = "An outcome group"
      log.description = "<p>Groupage</p>"
      log.save!
      old_root.adopt_outcome_group(log)

      lo2 = create_outcome(@copy_from, log)

      log_sub = @copy_from.learning_outcome_groups.new
      log_sub.context = @copy_from
      log_sub.title = "Sub group"
      log_sub.description = "<p>SubGroupage</p>"
      log_sub.save!
      log.adopt_outcome_group(log_sub)

      log_sub2 = @copy_from.learning_outcome_groups.new
      log_sub2.context = @copy_from
      log_sub2.title = "Sub group2"
      log_sub2.description = "<p>SubGroupage2</p>"
      log_sub2.save!
      log_sub.adopt_outcome_group(log_sub2)

      lo3 = create_outcome(@copy_from, log_sub2)

      # copy outcomes into new course
      new_root = @copy_to.root_outcome_group

      run_course_copy

      @copy_to.created_learning_outcomes.count.should == @copy_from.created_learning_outcomes.count
      @copy_to.learning_outcome_groups.count.should == @copy_from.learning_outcome_groups.count
      new_root.child_outcome_links.count.should == old_root.child_outcome_links.count
      new_root.child_outcome_groups.count.should == old_root.child_outcome_groups.count

      lo_new = new_root.child_outcome_links.first.content
      lo_new.short_description.should == lo.short_description
      lo_new.description.should == lo.description
      lo_new.data.should == lo.data

      log_new = new_root.child_outcome_groups.first
      log_new.title.should == log.title
      log_new.description.should == log.description
      log_new.child_outcome_links.length.should == 1

      lo_new = log_new.child_outcome_links.first.content
      lo_new.short_description.should == lo2.short_description
      lo_new.description.should == lo2.description
      lo_new.data.should == lo2.data

      log_sub_new = log_new.child_outcome_groups.first
      log_sub_new.title.should == log_sub.title
      log_sub_new.description.should == log_sub.description

      log_sub2_new = log_sub_new.child_outcome_groups.first
      log_sub2_new.title.should == log_sub2.title
      log_sub2_new.description.should == log_sub2.description

      lo3_new = log_sub2_new.child_outcome_links.first.content
      lo3_new.short_description.should == lo3.short_description
      lo3_new.description.should == lo3.description
      lo3_new.data.should == lo3.data
    end

    it "should not copy deleted learning outcomes into the new course" do
      old_root = @copy_from.root_outcome_group

      log = @copy_from.learning_outcome_groups.new
      log.context = @copy_from
      log.title = "An outcome group"
      log.description = "<p>Groupage</p>"
      log.save!
      old_root.adopt_outcome_group(log)

      lo = create_outcome(@copy_from, log)
      lo2 = create_outcome(@copy_from, log)
      lo2.destroy

      run_course_copy

      @copy_to.created_learning_outcomes.count.should == 1
      @copy_to.created_learning_outcomes.first.migration_id.should == mig_id(lo)
    end

    it "should relink to external outcomes" do
      account = @copy_from.account
      a_group = account.root_outcome_group

      root_group = LearningOutcomeGroup.create!(:title => "contextless group")

      lo = create_outcome(nil, root_group)

      lo2 = create_outcome(account, a_group)

      from_root = @copy_from.root_outcome_group
      from_root.add_outcome(lo)
      from_root.add_outcome(lo2)

      run_course_copy

      to_root = @copy_to.root_outcome_group
      to_root.child_outcome_links.count.should == 2
      to_root.child_outcome_links.find_by_content_id(lo.id).should_not be_nil
      to_root.child_outcome_links.find_by_content_id(lo2.id).should_not be_nil
    end

    it "should create outcomes in new course if external context not found" do
      hash = {"is_global_outcome"=>true,
               "points_possible"=>nil,
               "type"=>"learning_outcome",
               "ratings"=>[],
               "description"=>nil,
               "mastery_points"=>nil,
               "external_identifier"=>"0",
               "title"=>"root outcome",
               "migration_id"=>"id1072dcf40e801c6468d9eaa5774e56d"}

      @cm.outcome_to_id_map = {}
      Importers::LearningOutcomeImporter.import_from_migration(hash, @cm)

      @cm.warnings.should == ["The external Learning Outcome couldn't be found for \"root outcome\", creating a copy."]

      to_root = @copy_to.root_outcome_group
      to_root.child_outcome_links.count.should == 1
      new_lo = to_root.child_outcome_links.first.content
      new_lo.id.should_not == 0
      new_lo.short_description.should == hash["title"]
    end

    it "should create rubrics in new course if external context not found" do
      hash = {
              "reusable"=>false,
              "public"=>false,
              "hide_score_total"=>nil,
              "free_form_criterion_comments"=>nil,
              "points_possible"=>nil,
              "data"=>[{"id"=>"1",
                        "description"=>"Outcome row",
                        "long_description"=>nil,
                        "points"=>3,
                        "mastery_points"=>nil,
                        "title"=>"Outcome row",
                        "ratings"=>[{"description"=>"Rockin'",
                                     "id"=>"2",
                                     "criterion_id"=>"1", "points"=>3}]}],
              "read_only"=>false,
              "description"=>nil,
              "external_identifier"=>"0",
              "title"=>"root rubric",
              "migration_id"=>"id1072dcf40e801c6468d9eaa5774e56d"}

      @cm.outcome_to_id_map = {}
      Importers::RubricImporter.import_from_migration(hash, @cm)

      @cm.warnings.should == ["The external Rubric couldn't be found for \"root rubric\", creating a copy."]

      new_rubric = @copy_to.rubrics.first
      new_rubric.id.should_not == 0
      new_rubric.title.should == hash["title"]
    end

    it "should link rubric (and assignments) to outcomes" do
      root_group = LearningOutcomeGroup.create!(:title => "contextless group")

      lo = create_outcome(nil, root_group)
      lo2 = create_outcome(@copy_from)

      from_root = @copy_from.root_outcome_group
      from_root.add_outcome(lo)
      from_root.add_outcome(lo2)

      rub = Rubric.new(:context => @copy_from)
      rub.data = [
        {
          :points => 3,
          :description => "Outcome row",
          :id => 1,
          :ratings => [{:points => 3,:description => "Rockin'",:criterion_id => 1,:id => 2}],
          :learning_outcome_id => lo.id
        },
        {
          :points => 3,
          :description => "Outcome row 2",
          :id => 2,
          :ratings => [{:points => 3,:description => "lame'",:criterion_id => 2,:id => 3}],
          :ignore_for_scoring => true,
          :learning_outcome_id => lo2.id
        }
      ]
      rub.save!
      rub.associate_with(@copy_from, @copy_from)

      from_assign = @copy_from.assignments.create!(:title => "some assignment")
      rub.associate_with(from_assign, @copy_from, :purpose => "grading")

      run_course_copy

      new_lo2 = @copy_to.created_learning_outcomes.find_by_migration_id(mig_id(lo2))
      to_rub = @copy_to.rubrics.first
      to_assign = @copy_to.assignments.first

      to_rub.data[1]["learning_outcome_id"].should == new_lo2.id
      to_rub.data[1]["ignore_for_scoring"].should == true
      to_rub.data[0]["learning_outcome_id"].should == lo.id
      to_rub.learning_outcome_alignments.map(&:learning_outcome_id).sort.should == [lo.id, new_lo2.id].sort
      to_assign.learning_outcome_alignments.map(&:learning_outcome_id).sort.should == [lo.id, new_lo2.id].sort
    end

    it "should still associate rubrics and assignments and copy rubric association properties" do
      create_rubric_asmnt
      @assoc.summary_data = {:saved_comments=>{"309_6312"=>["what the comment", "hey"]}}
      @assoc.save!

      run_course_copy

      rub = @copy_to.rubrics.find_by_migration_id(mig_id(@rubric))
      rub.should_not be_nil

      [:description, :id, :points].each do |k|
        rub.data.first[k].should == @rubric.data.first[k]
      end
      [:criterion_id, :description, :id, :points].each do |k|
        rub.data.first[:ratings].each_with_index do |criterion, i|
          criterion[k].should == @rubric.data.first[:ratings][i][k]
        end
      end

      asmnt2 = @copy_to.assignments.find_by_migration_id(mig_id(@assignment))
      asmnt2.rubric.id.should == rub.id
      asmnt2.rubric_association.use_for_grading.should == true
      asmnt2.rubric_association.hide_score_total.should == true
      asmnt2.rubric_association.summary_data.should == @assoc.summary_data
    end

    it "should copy rubrics associated with assignments when rubric isn't selected" do
      create_rubric_asmnt
      @cm.copy_options = {
              :assignments => {mig_id(@assignment) => "1"},
      }
      @cm.save!
      run_course_copy

      rub = @copy_to.rubrics.find_by_migration_id(mig_id(@rubric))
      rub.should_not be_nil
      asmnt2 = @copy_to.assignments.find_by_migration_id(mig_id(@assignment))
      asmnt2.rubric.id.should == rub.id
    end
  end
end
