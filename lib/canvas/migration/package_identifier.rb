module Canvas::Migration
  class PackageIdentifier
    include Canvas::Migration::XMLHelper
    attr_reader :type, :converter

    def initialize(settings)
      unless settings[:archive_file]
        MigratorHelper::download_archive(settings)
      end
      @archive = settings[:archive_file]
      @type = :unknown
    end

    def get_converter
      @type = identify_package
      @converter = find_converter
    end

    def identify_package
      zip_file = Zip::File.open(@archive.path)
      if zip_file.find_entry("AngelManifest.xml")
        :angel_7_4
      elsif zip_file.find_entry("angelData.xml")
        :angel_7_3
      elsif zip_file.find_entry("moodle.xml")
        :moodle_1_9
      elsif zip_file.find_entry("moodle_backup.xml")
        :moodle_2
      elsif zip_file.find_entry("imsmanifest.xml")
        data = zip_file.read("imsmanifest.xml")
        doc = ::Nokogiri::XML(data)
        if get_node_val(doc, 'metadata schema') =~ /IMS Common Cartridge/i
          if !!doc.at_css(%{resources resource[href="#{CC::CCHelper::COURSE_SETTINGS_DIR}/#{CC::CCHelper::SYLLABUS}"] file[href="#{CC::CCHelper::COURSE_SETTINGS_DIR}/#{CC::CCHelper::COURSE_SETTINGS}"]})
            :canvas_cartridge
          elsif !!doc.at_css(%{resources resource[href="#{CC::CCHelper::COURSE_SETTINGS_DIR}/#{CC::CCHelper::CANVAS_EXPORT_FLAG}"]})
            :canvas_cartridge
          elsif get_node_val(doc, 'metadata schemaversion') == "1.0.0"
            :common_cartridge_1_0
          elsif get_node_val(doc, 'metadata schemaversion') == "1.1.0"
            :common_cartridge_1_1
          elsif get_node_val(doc, 'metadata schemaversion') == "1.2.0"
            :common_cartridge_1_2
          end
        elsif has_namespace(doc, "http://www.blackboard.com/content-packaging")
          :bb_learn
        elsif has_namespace(doc, "http://desire2learn.com/xsd/d2lcp")
          :d2l
        elsif has_namespace(doc, "http://www.webct.com/xsd/cisv3")
          :webct # only quizzes are supported
        elsif has_namespace(doc, "http://www.webct.com/IMS")
          :webct_4_1
        elsif has_namespace(doc, "http://www.adlnet.org/xsd/adl_cp_rootv1p1")
          :scorm_1_1
        elsif has_namespace(doc, "http://www.adlnet.org/xsd/adlcp_rootv1p2")
          :scorm_1_2
        elsif has_namespace(doc, "http://www.adlnet.org/xsd/adlcp_v1p3")
          :scorm_1_3 # scorm 2004
        elsif doc.at_css('resources resource[type^=ims_qti]')
          :qti
        elsif doc.at_css('resources resource[type^=imsqti]')
          :qti
        else
          # generic IMS Content Package?
          :unknown_ims_cp_package
        end
      else
        :unknown
      end
    rescue Zip::Error
      # Not a valid zip file
      :invalid_archive
    end
    
    :private
    
    def has_namespace(node, namespace)
      node.namespaces.values.any?{|ns|ns =~ /#{namespace}/i}
    end
    
    def find_converter
      if plugin = Canvas::Plugin.all_for_tag(:export_system).find{|p|p.settings[:provides] && p.settings[:provides][@type]}
        return plugin.settings[:provides][@type]
      end
      raise Canvas::Migration::Error, I18n.t(:unsupported_package, "Unsupported content package")
    end
  end
end
