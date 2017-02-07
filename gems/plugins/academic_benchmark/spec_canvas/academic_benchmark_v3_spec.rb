
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe AcademicBenchmark::Converter do

  before(:each) do
    @root_account = Account.site_admin
    account_admin_user(:account => @root_account, :active_all => true)
    @cm = ContentMigration.new(:context => @root_account)
    @plugin = Canvas::Plugin.find('academic_benchmark_importer')
    @cm.converter_class = @plugin.settings['converter_class']
    @cm.migration_settings[:migration_type] = 'academic_benchmark_importer'
    @cm.migration_settings[:import_immediately] = true
    @cm.migration_settings[:migration_options] = {points_possible: 10, mastery_points: 6,
      ratings: [{description: 'Bad', points: 0}, {description: 'Awesome', points: 10}]}
    @cm.user = @user
    @cm.save!

    @plugin.settings[:partner_id] = "instructure"
    @plugin.settings[:partner_key] = "secret"

    @level_0_browse = File.join(File.dirname(__FILE__) + '/fixtures', 'api_all_standards_response.json')
    @florida_auth_list = File.join(File.dirname(__FILE__) + '/fixtures', 'florida_auth_list_v3.json')
    File.open(@level_0_browse, 'r') do |file|
      @att = Attachment.create!(
        :filename => 'standards.json',
        :display_name => 'standards.json',
        :uploaded_data => file,
        :context => @cm
      )
    end
    @cm.attachment = @att
    @cm.save!
  end

  def verify_rubric_criterion(outcome)
    expect(outcome.data[:rubric_criterion][:mastery_points]).to eq 6
    expect(outcome.data[:rubric_criterion][:points_possible]).to eq 10
    expect(outcome.data[:rubric_criterion][:ratings]).to eq [{description: 'Bad', points: 0},
                                                             {description: 'Awesome', points: 10}]
  end

  def verify_full_import
    @root_group = LearningOutcomeGroup.global_root_outcome_group
    expect(@root_group.child_outcome_groups.count).to eq 2
    a = @root_group.child_outcome_groups.first
    expect(a.migration_id).to eq "CEC2CF6C-67AD-11DF-AB5F-995D9DFF4B22"
    expect(a.title).to eq "CCSS.ELA-Literacy.CCRA.R - Reading"
    b = a.child_outcome_groups.first
    expect(b.migration_id).to eq "CEB79A48-67AD-11DF-AB5F-995D9DFF4B22"
    expect(b.title).to eq "Key Ideas and Details"
    g = LearningOutcome.global.where(migration_id: "CEB87C92-67AD-11DF-AB5F-995D9DFF4B22").first
    verify_rubric_criterion(g)
    expect(g.short_description).to eq "CCSS.ELA-Literacy.CCRA.R.1"
    expect(g.description).to eq "Read closely to determine what the text says explicitly and to make logical" \
      " inferences from it; cite specific textual evidence when writing or speaking to support conclusions drawn" \
      " from the text."
    g = LearningOutcome.global.where(migration_id: "CEB8EE66-67AD-11DF-AB5F-995D9DFF4B22").first
    verify_rubric_criterion(g)
    expect(g.short_description).to eq "CCSS.ELA-Literacy.CCRA.R.2"
    expect(g.description).to eq "Determine central ideas or themes of a text and analyze their development;" \
      " summarize the key supporting details and ideas."
    g = LearningOutcome.global.where(migration_id: "CEB96684-67AD-11DF-AB5F-995D9DFF4B22").first
    verify_rubric_criterion(g)
    expect(g.short_description).to eq "CCSS.ELA-Literacy.CCRA.R.3"
    expect(g.description).to eq "Analyze how and why individuals, events, and ideas develop and interact over" \
      " the course of a text."
    g = LearningOutcome.global.where(migration_id: "CEBAB958-67AD-11DF-AB5F-995D9DFF4B22").first
    verify_rubric_criterion(g)
    expect(g.short_description).to eq "CCSS.ELA-Literacy.CCRA.R.4"
    expect(g.description).to eq "Interpret words and phrases as they are used in a text, including determining" \
      " technical, connotative, and figurative meanings, and analyze how specific word choices shape meaning or tone."
    g = LearningOutcome.global.where(migration_id: "CEBB9AA8-67AD-11DF-AB5F-995D9DFF4B22").first
    verify_rubric_criterion(g)
    expect(g.short_description).to eq "CCSS.ELA-Literacy.CCRA.R.5"
    expect(g.description).to eq "Analyze the structure of texts, including how specific sentences, paragraphs," \
      " and larger portions of the text (e.g., a section, chapter, scene, or stanza) relate to each other and" \
      " the whole."
    g = LearningOutcome.global.where(migration_id: "CEBC89F4-67AD-11DF-AB5F-995D9DFF4B22").first
    verify_rubric_criterion(g)
    expect(g.short_description).to eq "CCSS.ELA-Literacy.CCRA.R.6"
    expect(g.description).to eq "Assess how point of view or purpose shapes the content and style of a text."
    g = LearningOutcome.global.where(migration_id: "CEBDDCA0-67AD-11DF-AB5F-995D9DFF4B22").first
    verify_rubric_criterion(g)
    expect(g.short_description).to eq "CCSS.ELA-Literacy.CCRA.R.7"
    expect(g.description).to eq "Integrate and evaluate content presented in diverse media and formats," \
      " including visually and quantitatively, as well as in words."
    g = LearningOutcome.global.where(migration_id: "CEBE4D52-67AD-11DF-AB5F-995D9DFF4B22").first
    verify_rubric_criterion(g)
    expect(g.short_description).to eq "CCSS.ELA-Literacy.CCRA.R.8"
    expect(g.description).to eq "Delineate and evaluate the argument and specific claims in a text," \
      " including the validity of the reasoning as well as the relevance and sufficiency of the evidence."
    g = LearningOutcome.global.where(migration_id: "CEBF37B2-67AD-11DF-AB5F-995D9DFF4B22").first
    verify_rubric_criterion(g)
    expect(g.short_description).to eq "CCSS.ELA-Literacy.CCRA.R.9"
    expect(g.description).to eq "Analyze how two or more texts address similar themes or topics in order" \
      " to build knowledge or to compare the approaches the authors take."
    g = LearningOutcome.global.where(migration_id: "CEC08B44-67AD-11DF-AB5F-995D9DFF4B22").first
    verify_rubric_criterion(g)
    expect(g.short_description).to eq "CCSS.ELA-Literacy.CCRA.R.10"
    expect(g.description).to eq "Read and comprehend complex literary and informational texts independently" \
      " and proficiently."
    g = LearningOutcome.global.where(migration_id: "CEC49A36-67AD-11DF-AB5F-995D9DFF4B22").first
    verify_rubric_criterion(g)
    expect(g.short_description).to eq "CCSS.ELA-Literacy.CCRA.W.1"
    expect(g.description).to eq "Write arguments to support claims in an analysis of substantive topics or" \
      " texts, using valid reasoning and relevant and sufficient evidence."
    g = LearningOutcome.global.where(migration_id: "CEC57CD0-67AD-11DF-AB5F-995D9DFF4B22").first
    verify_rubric_criterion(g)
    expect(g.short_description).to eq "CCSS.ELA-Literacy.CCRA.W.2"
    expect(g.description).to eq "Write informative/explanatory texts to examine and convey complex ideas and" \
      " information clearly and accurately through the effective selection, organization, and analysis of content."
    g = LearningOutcome.global.where(migration_id: "CEC665B4-67AD-11DF-AB5F-995D9DFF4B22").first
    verify_rubric_criterion(g)
    expect(g.short_description).to eq "CCSS.ELA-Literacy.CCRA.W.3"
    expect(g.description).to eq "Write narratives to develop real or imagined experiences or events" \
      " using effective technique, well-chosen details, and well-structured event sequences."
  end

  def check_for_parent_num_duplication(outcome)
    parent = outcome.instance_variable_get('@parent')
    if outcome.number && parent && parent.build_title && outcome.number.include?(parent.build_title)
      outcome.title == "#{parent.title}.#{outcome.number}"
    else
      false
    end
  end

  def check_built_outcome(outcome)
    expect(check_for_parent_num_duplication(outcome)).to be_falsey
    outcome.instance_variable_get('@children').each { |o| check_built_outcome(o) }
  end

  it "should successfully import the standards" do
    @cm.export_content
    run_jobs
    @cm.reload
    expect(@cm.migration_issues.count).to eq 0
    expect(@cm.workflow_state).to eq 'imported'

    verify_full_import()
  end

  it "should reject creating global outcomes if no permissions" do
    @cm.user = nil
    @cm.save!
    @cm.export_content
    run_jobs
    @cm.reload

    expect(@cm.migration_issues.count).to eq 1
    expect(@cm.migration_issues.first.description).to eq "User isn't allowed to edit global outcomes"
    expect(@cm.workflow_state).to eq 'failed'
  end

  context "using the API" do
    append_before do
      @cm.attachment = nil
      @cm.migration_settings[:no_archive_file] = true
      @cm.migration_settings[:authorities] = ["CC"]
      @cm.save!
    end

    it "should fail with no partner ID" do
      @plugin.settings['api_key'] = nil
      @plugin.settings[:partner_id] = nil
      @plugin.settings[:partner_key] = "a"
      @cm.export_content
      run_jobs
      @cm.reload

      expect(@cm.migration_issues.count).to eq 1
      expect(@cm.migration_issues.first.description).to eq "A partner ID is required to use Academic Benchmarks"
      expect(@cm.workflow_state).to eq 'failed'
    end

    it "should fail with an empty string partner ID" do
      @plugin.settings['api_key'] = nil
      @plugin.settings[:partner_id] = ""
      @plugin.settings[:partner_key] = "a"
      @cm.export_content
      run_jobs
      @cm.reload

      expect(@cm.migration_issues.count).to eq 1
      expect(@cm.migration_issues.first.description).to eq "A partner ID is required to use Academic Benchmarks"
      expect(@cm.workflow_state).to eq 'failed'
    end
  end

  # This test came about because the titles being generated for
  # Florida outcomes were long and out of control.  They were looking
  # like this:
  #
  #    LAFS.1.L.LAFS.1.L.1.LAFS.1.L.1.1.a
  #
  # instead of this:
  #
  #    LAFS.1.L.1.1.a
  #
  it "doesn't duplicate the base numbers when building a title" do
    json_data = JSON.parse(File.read(@florida_auth_list))
    AcademicBenchmarks::Standards::StandardsForest.new(json_data).trees.each do |tree|
      tree.children.each do |outcome|
        check_built_outcome(outcome)
      end
    end
  end

  it "raises error with invalid user id" do
    expect { AcademicBenchmark.ensure_real_user(user_id: 0) }.to raise_error(Canvas::Migration::Error,
      "Not importing academic benchmark data because no user found matching id '0'")
  end

  it "raises error when crendentials are not set" do
    AcademicBenchmark.stubs(:config).returns({})
    expect{ AcademicBenchmark.ensure_ab_credentials }.to raise_error(Canvas::Migration::Error,
      "Not importing academic benchmark data because the Academic Benchmarks Partner ID is not set")
    AcademicBenchmark.stubs(:config).returns({partner_id: "user"})
    expect{ AcademicBenchmark.ensure_ab_credentials }.to raise_error(Canvas::Migration::Error,
      "Not importing academic benchmark data because the Academic Benchmarks Partner key is not set")
  end
end
