module CC::Exporter::Epub
  module ModuleSorter
    def filter_syllabus_for_modules
      return false if sort_by_content
      cartridge_json[:modules].each do |mod|
        update_syllabus_item(mod)
      end
      cartridge_json[:syllabus].select!{|item| item[:in_module]}
      # need this for edge cases where there might not be any syllabus items
      true
    end

    def update_syllabus_item(mod)
      mod[:items].map do |mod_item|
        syllabus_item = cartridge_json[:syllabus].find do |item|
          item[:identifier] == module_syllabus_resource(mod_item)
        end
        if syllabus_item
          syllabus_item[:href] = mod_item[:href]
          syllabus_item[:in_module] = true
        end
      end
    end

    def filter_content_to_module(module_id)
      current_mod = cartridge_json[:modules].find{|mod| mod["migration_id"] == module_id}
      current_mod[:items].map do |item|
        merge_with_original_item_data(item)
      end
      current_mod
    end

    private
    def module_ids
      cartridge_json[:modules].map{|mod| mod["migration_id"]}
    end

    def module_syllabus_resource(mod_item)
      return false unless mod_item[:for_syllabus]
      mod_item[:linked_resource_id]
    end

    def merge_with_original_item_data(module_item)
      resource_type = Exporter::LINKED_RESOURCE_KEY[module_item[:linked_resource_type]]
      identifier = module_item[:linked_resource_id]
      original_item_data = get_item(resource_type, identifier)

      module_item.reverse_merge!(original_item_data)
      update_item(resource_type, identifier, {href: module_item[:href]})
    end
  end
end
