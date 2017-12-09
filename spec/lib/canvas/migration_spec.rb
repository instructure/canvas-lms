#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe "Migration package importers" do

  context "Detecting content package type" do

    def get_settings(name)
      if !name.ends_with?('xml')
        name += '.zip'
      end
      path = File.dirname(__FILE__) + "/../../fixtures/migration/package_identifier/#{name}"
      {:export_archive_path=>path}
    end

    supported = {
            "Old Canvas Cartridge" => ['old_canvas', CC::Importer::Canvas::Converter],
            "Canvas Cartridge" => ['canvas', CC::Importer::Canvas::Converter],
            "Common Cartridge 1.0" => ["cc1-0", CC::Importer::Standard::Converter],
            "Common Cartridge 1.1" => ["cc1-1", CC::Importer::Standard::Converter],
            "Common Cartridge 1.2" => ["cc1-2", CC::Importer::Standard::Converter],
            "Common Cartridge 1.3" => ["cc1-3", CC::Importer::Standard::Converter],
            "Common Cartridge 1.3 - flat" => ["cc1-3flat.xml", CC::Importer::Standard::Converter],
            "Common Cartridge 1.3 - thin" => ["cc1-3thin.xml", CC::Importer::Standard::Converter],
            "QTI packages" => ['qti', Qti::Converter],
            "WebCT exports (as qti packages)" => ['webct', Qti::Converter],
    }

    unsupported = {
            "Blackboard packages" => ['bb_learn', :bb_learn],
            "Angel 7.3 packages" => ["angel7-3", :angel_7_3],
            "Angel 7.4 packages" => ["angel7-4", :angel_7_4],
            "D2L packages" => ['d2l', :d2l],
            "Generic IMS Content Package" => ['ims_cp', :unknown_ims_cp_package],
            "Moodle 1.9 Package" => ["moodle1-9", :moodle_1_9],
            "Moodle 2 Package" => ["moodle2", :moodle_2],
            "SCORM 1.1 Package" => ["scorm1-1", :scorm_1_1],
            "SCORM 1.2 Package" => ["scorm1-2", :scorm_1_2],
            "SCORM 1.3 Package" => ["scorm1-3", :scorm_1_3],
            "Unknown zip Package" => ["unknown", :unknown],
            "WebCT 4.1 Package" => ["webct4-1", :webct_4_1],
    }

    supported.each_pair do |key, val|
      it "should find converter for #{key}" do
        settings = get_settings(val.first)
        expect(Canvas::Migration::Worker::get_converter(settings)).to eq val.last
      end
    end

    unsupported.each_pair do |key, val|
      it "should correctly identify package type for #{key}" do
        settings = get_settings(val.first)
        archive = Canvas::Migration::Archive.new(settings)
        expect(Canvas::Migration::PackageIdentifier.new(archive).identify_package).to eq val.last
      end
    end

    it "should raise a traceable error for invalid packages" do
      settings = get_settings('invalid')
      archive = Canvas::Migration::Archive.new(settings)
      expect{
        Canvas::Migration::PackageIdentifier.new(archive).identify_package
      }.to raise_error(Canvas::Migration::Error, "Error identifying package type: unknown mime type text/plain")
    end
  end

  context "migrator" do
    it "should deal with backslashes path separators in migrations" do
      file = File.new(File.dirname(__FILE__) + "/../../fixtures/migration/whatthebackslash.zip")
      cm = ContentMigration.create!(:context => course_factory)

      mig = Canvas::Migration::Migrator.new({:archive_file => file, :content_migration => cm}, "test")
      mig.unzip_archive
      expect(File).to be_exist(mig.package_root.item_path('messaging/why oh why.txt'))
      expect(File).to be_exist(mig.package_root.item_path('res00175/SR_Epilogue_Frequently_Asked_Questions.html'))
    end

    it "creates overview assignments for graded discussion topics and quizzes and pages" do
      mig = Canvas::Migration::Migrator.new({:no_archive_file => true}, "test")
      mig.course = {
        :assignment_groups => [{
          :migration_id => "iee2a87de283cb9290ee8f39330e1cd13",
          :title => "ASSIGNMENT GROUP LOL",
        }],
        :discussion_topics => [{
          :title => "GRATED DISCUSSION",
          :migration_id => "i666db8c76308d6bd5a8db8f063ec75c5",
          :type => "topic",
          :assignment => {
            :title => "GRATED DISCUSSION",
            :migration_id => "ie088c19c90e7bb4cbc1a1ad1fd5945a0",
            :assignment_group_migration_id => "iee2a87de283cb9290ee8f39330e1cd13"
          }
        }],
        :wikis => [{
          :title => "COOL PAGE",
          :migration_id => "i75f3638d3f385cae601b525e03dddcc5",
          :type => "wiki_pages",
          :assignment => {
            :title => "COOL PAGE",
            :migration_id => "i2102a7fa93b29226774949298626719d",
            :assignment_group_migration_id => "iee2a87de283cb9290ee8f39330e1cd13"
          }
        }],
        :assessments => {
          :assessments => [{
            :title => "STUPID QUIZ",
            :migration_id => "i6bdad32159d1447f376fed88e15b8075",
            :assignment => {
              :title => "STUPID QUIZ",
              :migration_id => "iaa6f6db92ef0a3b7ee11a636858b691e",
              :assignment_group_migration_id => "iee2a87de283cb9290ee8f39330e1cd13",
            }
          }]
        }
      }
      overview = mig.overview
      expect(overview[:assessments][0][:assignment_migration_id]).to eq 'iaa6f6db92ef0a3b7ee11a636858b691e'
      expect(overview[:discussion_topics][0][:assignment_migration_id]).to eq 'ie088c19c90e7bb4cbc1a1ad1fd5945a0'
      expect(overview[:wikis][0][:assignment_migration_id]).to eq 'i2102a7fa93b29226774949298626719d'
      expect(overview[:assignment_groups]).to eq([{:migration_id => "iee2a87de283cb9290ee8f39330e1cd13",
                                                   :title => "ASSIGNMENT GROUP LOL"}])
      expect(overview[:assignments]).to match_array([{:title => "STUPID QUIZ",
                                                      :migration_id => "iaa6f6db92ef0a3b7ee11a636858b691e",
                                                      :assignment_group_migration_id => "iee2a87de283cb9290ee8f39330e1cd13",
                                                      :quiz_migration_id => "i6bdad32159d1447f376fed88e15b8075"},
                                                     {:title => "GRATED DISCUSSION",
                                                      :migration_id => "ie088c19c90e7bb4cbc1a1ad1fd5945a0",
                                                      :assignment_group_migration_id => "iee2a87de283cb9290ee8f39330e1cd13",
                                                      :topic_migration_id => "i666db8c76308d6bd5a8db8f063ec75c5"},
                                                     {:title => "COOL PAGE",
                                                      :migration_id => "i2102a7fa93b29226774949298626719d",
                                                      :assignment_group_migration_id => "iee2a87de283cb9290ee8f39330e1cd13",
                                                      :page_migration_id => "i75f3638d3f385cae601b525e03dddcc5"}])
    end
  end

end
