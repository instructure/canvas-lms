module CC::Exporter::Epub::Converters
  class CartridgeConverter < Canvas::Migration::Migrator
    include Canvas::Migration::XMLHelper
    include WikiEpubConverter
    include AssignmentEpubConverter
    include TopicEpubConverter
    include QuizEpubConverter

    MANIFEST_FILE = "imsmanifest.xml"

    # settings will use these keys: :course_name, :base_download_dir
    def initialize(settings)
      super(settings, "cc")
      @course = @course.with_indifferent_access
      @resources = {}
      @resource_nodes_for_flat_manifest = {}
    end

    def export_directory
      File.dirname(@archive.file)
    end

    # exports the package into the intermediary json
    def export
      unzip_archive
      set_progress(5)

      @manifest = open_file(File.join(@unzipped_file_path, MANIFEST_FILE))
      get_all_resources(@manifest)

      @course[:title] = get_node_val(@manifest, "string")
      set_progress(10)
      @course[:wikis] = convert_wikis
      set_progress(20)
      @course[:assignments] = convert_assignments
      set_progress(30)
      @course[:discussion_topics] = convert_topics
      set_progress(40)
      @course[:quizzes] = convert_quizzes

      save_to_file
      set_progress(90)
      delete_unzipped_archive
      @course
    end
  end
end
