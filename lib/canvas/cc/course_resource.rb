#
# Copyright (C) 2011 Instructure, Inc.
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
#
module Canvas::CC
  module CourseResource

    def add_course_settings
      #todo - add assignment group weighting and grading schemes
      migration_id = create_key(@course)
      
      lo_folder = File.join(@export_dir, CCHelper::COURSE_SETTINGS_DIR)
      FileUtils::mkdir_p lo_folder

      file_name = CCHelper::SYLLABUS
      syl_rel_path = File.join(CCHelper::COURSE_SETTINGS_DIR, file_name)
      path = File.join(lo_folder, file_name)
      File.open(path, 'w') do |file|
        file << CCHelper.html_page(@course.syllabus_body || '', "Syllabus", @course, @manifest.exporter.user)
      end

      course_rel_path = create_course_settings(lo_folder, migration_id)
      modules_rel_path = create_module_meta(lo_folder)
      
      @resources.resource(
              :identifier => migration_id,
              "type" => Manifest::LOR,
              :href => syl_rel_path
      ) do |res|
        res.file(:href=>syl_rel_path)
        res.file(:href=>course_rel_path)
        res.file(:href=>modules_rel_path) if modules_rel_path
      end
    end
    
    def create_course_settings(lo_folder, migration_id)
      course_file = File.new(File.join(lo_folder, CCHelper::COURSE_SETTINGS), 'w')
      rel_path = File.join(CCHelper::COURSE_SETTINGS_DIR, CCHelper::COURSE_SETTINGS)
      document = Builder::XmlMarkup.new(:target=>course_file, :indent=>2)
      document.instruct!
      document.course("identifier" => migration_id,
                      "xmlns" => CCHelper::CANVAS_NAMESPACE,
                      "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
                      "xsi:schemaLocation"=> "#{CCHelper::CANVAS_NAMESPACE} #{CCHelper::XSD_URI}"
      ) do |c|
        c.title @course.name
        c.start_at ims_datetime(@course.start_at) if @course.start_at
        c.conclude_at ims_datetime(@course.conclude_at) if @course.conclude_at
        atts = Course.clonable_attributes
        atts -= [:name, :start_at, :conclude_at, :grading_standard_id, :hidden_tabs, :tab_configuration, :syllabus_body]
        atts.each do |att|
          c.tag!(att, @course.send(att)) unless @course.send(att).blank?
        end
      end
      course_file.close
      rel_path
    end
    
    def create_module_meta(lo_folder)
      return nil unless @course.context_modules.active.count > 0
      
      module_id_map = {}
      meta_file = File.new(File.join(lo_folder, CCHelper::MODULE_META), 'w')
      rel_path = File.join(CCHelper::COURSE_SETTINGS_DIR, CCHelper::MODULE_META)
      document = Builder::XmlMarkup.new(:target=>meta_file, :indent=>2)
      document.instruct!
      document.modules(
              "xmlns" => CCHelper::CANVAS_NAMESPACE,
              "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
              "xsi:schemaLocation"=> "#{CCHelper::CANVAS_NAMESPACE} #{CCHelper::XSD_URI}"
      ) do |mods_node|
        @course.context_modules.active.each do |cm|
          mod_migration_id = CCHelper.create_key(cm)
          # context modules are in order and a pre-req can only reference
          # a previous module, so just adding as we go is okay
          module_id_map[cm.id] = mod_migration_id
          
          mods_node.module(:identifier=>mod_migration_id) do |m_node|
            m_node.title cm.name
            m_node.position cm.position
            m_node.unlock_at CCHelper::ims_datetime(cm.unlock_at) if cm.unlock_at
            m_node.start_at CCHelper::ims_datetime(cm.start_at) if cm.start_at
            m_node.end_at CCHelper::ims_datetime(cm.end_at) if cm.end_at
            m_node.require_sequential_progress cm.require_sequential_progress.to_s
            
            if cm.prerequisites && !cm.prerequisites.empty?
              m_node.prerequisites do |pre_reqs|
                cm.prerequisites.each do |pre_req|
                  pre_reqs.prerequisite(:type=>pre_req[:type]) do |pr|
                    pr.title pre_req[:name]
                    pr.identifierref module_id_map[pre_req[:id]]
                  end
                end
              end
            end
            
            ct_id_map = {}
            m_node.contentTags do |cts_node|
              cm.content_tags.active.each do |ct|
                ct_migration_id = CCHelper.create_key(ct)
                ct_id_map[ct.id] = ct_migration_id
                cts_node.contentTag(:identifier=>ct_migration_id) do |ct_node|
                  ct_node.content_type ct.content_type
                  ct_node.identifierref CCHelper.create_key(ct.content) unless ct.content_type == 'ContextModuleSubHeader'
                  ct_node.url ct.url if ct.content_type == 'ExternalUrl'
                  ct_node.position ct.position
                  ct_node.indent ct.indent
                end
              end
            end
            
            if cm.completion_requirements && !cm.completion_requirements.empty?
              m_node.completionRequirements do |crs_node|
                cm.completion_requirements.each do |c_req|
                  crs_node.completionRequirement(:type=>c_req[:type]) do |cr_node|
                    cr_node.min_score c_req[:min_score] unless c_req[:min_score].blank?
                    cr_node.max_score c_req[:max_score] unless c_req[:max_score].blank?
                    cr_node.identifierref ct_id_map[c_req[:id]]
                  end
                end
              end
            end
            
          end
        end
      end
      meta_file.close
      rel_path
    end

  end
end
