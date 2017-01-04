require 'spec_helper'

describe AcademicBenchmark::Converter do
  def common_std
    {
      "placeholder"=>"N",
      "date_modified"=>"2004-11-30 17:05:24",
      "subject"=>{"code"=>"TECH", "broad"=>"TECH"},
      "deepest"=>"Y",
      "version"=>"0",
      "status"=>"Active",
      "document"=>{"guid"=>"99395B3C-C0DA-11DA-8BD7-97BD8BBE078D", "title"=>"NETS for Students", "acronym"=>"ISTE"},
      "descr"=>"Use input devices (e.g., mouse, keyboard, remote control) and output devices (e.g., monitor, printer) to successfully operate computers, VCRs, audiotapes, and other technologies. (1)",
      "grade"=>{"seq"=>"150", "high"=>"2", "low"=>"PK"},
      "level"=>1,
      "authority"=>{"code"=>"NT", "guid"=>"A834CC02-901A-11DF-A622-0C319DFF4B22", "descr"=>"National Standards"},
      "self"=>"http://api.academicbenchmarks.com/rest/v3/standards/e5a9ee98-33ac-446f-90a6-e8bbb053020f",
      "adopt_year"=>"2000"
    }
  end
  let(:raw_standard) do
    {"data"=>
      common_std.merge({
        "label"=>"Performance Indicator",
        "guid"=>"e5a9ee98-33ac-446f-90a6-e8bbb053020f",
        "subject_doc"=>{"guid"=>"E437624A-FC32-11D9-8407-9AE6FB2C8371", "descr"=>"Performance Indicators (2000)"},
        "course"=>{"guid"=>"82486BA4-4302-11D9-8407-9AE6FB2C8371", "descr"=>"PreK-2"},
        "number"=>"1"
      })
    }
  end
  # same subject and same course
  let(:raw_standard2) do
    {"data"=>
      common_std.merge({
        "label"=>"Performance Indicator 2",
        "guid"=>"e5a9ee98-33ac-446f-90a6-e8bbb053021f",
        "subject_doc"=>{"guid"=>"E437624A-FC32-11D9-8407-9AE6FB2C8371", "descr"=>"Performance Indicators (2000)"},
        "course"=>{"guid"=>"82486BA4-4302-11D9-8407-9AE6FB2C8371", "descr"=>"PreK-2"}
      })
    }
  end
  # new subject and new course
  let(:raw_standard3) do
    {"data"=>
      common_std.merge({
        "label"=>"Performance Indicator 3",
        "guid"=>"e5a9ee98-33ac-446f-90a6-e8bbb053022f",
        "subject_doc"=>{"guid"=>"E437624A-FC32-11D9-8407-9AE6FB2C8372", "descr"=>"Performance Indicators (2016)"},
        "course"=>{"guid"=>"82486BA4-4302-11D9-8407-9AE6FB2C8373", "descr"=>"4-6"},
        "number"=>"1"
      })
    }
  end
  # same subject but new course
  let(:raw_standard4) do
    {"data"=>
      common_std.merge({
        "label"=>"Performance Indicator 4",
        "guid"=>"e5a9ee98-33ac-446f-90a6-e8bbb053023f",
        "subject_doc"=>{"guid"=>"E437624A-FC32-11D9-8407-9AE6FB2C8371", "descr"=>"Performance Indicators (2000)"},
        "course"=>{"guid"=>"82486BA4-4302-11D9-8407-9AE6FB2C8372", "descr"=>"2-4"}
      })
    }
  end
  # Child of standard4
  let(:raw_standard5) do
    {"data"=>
      common_std.merge({
        "label"=>"Performance Indicator 5",
        "guid"=>"e5a9ee98-33ac-446f-90a6-e8bbb053024f",
        "parent"=>"e5a9ee98-33ac-446f-90a6-e8bbb053023f",
        "subject_doc"=>{"guid"=>"E437624A-FC32-11D9-8407-9AE6FB2C8371", "descr"=>"Performance Indicators (2000)"},
        "course"=>{"guid"=>"82486BA4-4302-11D9-8407-9AE6FB2C8372", "descr"=>"2-4"},
        "number"=>"2"
      })
    }
  end
  let(:raw_authority) do
    raw_standard['data']['authority']
  end
  let(:raw_document) do
    raw_standard['data']['document']
  end
  let(:authority_instance) do
    AcademicBenchmarks::Standards::Authority.from_hash(raw_authority)
  end
  let(:document_instance) do
    AcademicBenchmarks::Standards::Document.from_hash(raw_document)
  end
  let(:standard_instance) do
    AcademicBenchmarks::Standards::Standard.new(raw_standard)
  end
  let(:standard_instance2) do
    AcademicBenchmarks::Standards::Standard.new(raw_standard2)
  end
  let(:standard_instance3) do
    AcademicBenchmarks::Standards::Standard.new(raw_standard3)
  end
  let(:standard_instance4) do
    AcademicBenchmarks::Standards::Standard.new(raw_standard4)
  end
  let(:standard_instance5) do
    AcademicBenchmarks::Standards::Standard.new(raw_standard5)
  end
  let(:root_account) { Account.site_admin }
  let(:admin_user) { account_admin_user(account: root_account, active_all: true) }
  let(:regular_user) { user_factory(name: "regular user", short_name: "user") }
  let(:migration_settings) do
    {
      authority: @authority_guid,
      converter_class: 'AcademicBenchmark::Converter',
      document: @document_guid,
      import_immediately: true,
      migration_type: 'academic_benchmark_importer',
      no_archive_file: true,
      skip_import_notification: true,
      skip_job_progress: true
    }
  end
  let(:content_migration) do
    ContentMigration.create({
      context: root_account,
      migration_settings: migration_settings,
      user: @user
    })
  end
  let(:converter_settings) do
    migration_settings.merge({
      content_migration: content_migration,
      content_migration_id: content_migration.id,
      user_id: content_migration.user_id,
      migration_options: {points_possible: 10,
                          mastery_points: 6,
                          ratings: [{:description => "Awesome", :points => 10},
                                    {:description => "Not awesome", :points => 0}]}
    })
  end
  before do
    AcademicBenchmark.stubs(:config).returns({partner_id: "instructure", partner_key: "key"})
    standards_mock = mock("standards")
    standards_mock.stubs(:authority_tree).returns(
      AcademicBenchmarks::Standards::StandardsForest.new([standard_instance, standard_instance2, standard_instance3,
        standard_instance4, standard_instance5]).consolidate_under_root(authority_instance)
    )
    AcademicBenchmarks::Api::Standards.stubs(:new).returns(standards_mock)
    @user = admin_user
  end
  subject(:converter) do
    AcademicBenchmark::Converter.new(converter_settings)
  end

  describe '#export' do
    context 'when content_migration settings are missing' do
      before do
        converter.stubs(:content_migration).returns(nil)
      end

      it 'raises error missing content_migration settings' do
        expect {converter.export }.to raise_error(Canvas::Migration::Error,
          "Missing required content_migration settings")
      end
    end

    context 'when user does not have rights to :manage_global_outcomes' do
      before do
        @user = regular_user
      end

      it 'raises error cannot manage global outcomes' do
        expect {converter.export }.to raise_error(Canvas::Migration::Error,
          "User isn't allowed to edit global outcomes")
      end
    end

    context 'when an authority guid is provided' do
      before do
        @authority_guid = raw_authority['guid']
      end

      it 'sets course outcomes based on authority guid data' do
        expect(course = converter.export).to be_truthy
        expect(course["learning_outcomes"].count).to eql 1
        authority = course["learning_outcomes"].first
        expect(authority['type']).to eql "learning_outcome_group"
        expect(authority['title']).to eql "National Standards"
        expect(authority["outcomes"].count).to eql 1
        document = authority["outcomes"].first
        expect(document['type']).to eql "learning_outcome_group"
        expect(document['title']).to eql "NETS for Students"
        expect(document["outcomes"].count).to eql 2
        group1 = document["outcomes"].first
        group2 = document["outcomes"].second
        expect(group1['type']).to eql "learning_outcome_group"
        expect(group1['title']).to eql "Performance Indicators (2000)"
        expect(group2['type']).to eql "learning_outcome_group"
        expect(group2['title']).to eql "Performance Indicators (2016)"
        expect(group1["outcomes"].count).to eql 2
        expect(group2["outcomes"].count).to eql 1
        group11 = group1["outcomes"].first
        group12 = group1["outcomes"].second
        expect(group11['type']).to eql "learning_outcome_group"
        expect(group11['title']).to eql "PreK-2"
        expect(group12['type']).to eql "learning_outcome_group"
        expect(group12['title']).to eql "2-4"
        expect(group11["outcomes"].count).to eql 2
        outcome = group11["outcomes"].first
        expect(outcome['type']).to eql "learning_outcome"
        expect(outcome['title']).to eql "1"
        expect(outcome['mastery_points']).to eql 6
        expect(outcome['points_possible']).to eql 10
        expect(outcome['ratings'].length).to eql 2
        outcome = group11["outcomes"].second
        expect(outcome['type']).to eql "learning_outcome"
        expect(outcome['title']).to eql "Use input devices (e.g., mouse, keyboard, remote c"
        group21 = group2["outcomes"].first
        expect(group21['type']).to eql "learning_outcome_group"
        expect(group21['title']).to eql "4-6"
        expect(group12["outcomes"].count).to eql 1
        group121 = group12["outcomes"].first
        expect(group121['title']).to eql "Use input devices (e.g., mouse, keyboard, remote c"
        expect(group121["outcomes"].count).to eql 1
        outcome = group121["outcomes"].first
        expect(outcome["title"]).to eql "2"
      end
    end
  end
end

