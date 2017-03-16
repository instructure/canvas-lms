module DataFixup
  module BackfillNulls
    def self.run(klass, fields, default_value: false)
      klass.where("#{fields.join(' IS NULL OR ')} IS NULL").find_ids_in_ranges do |start_id, end_id|
        fields.each { |field| klass.where(id: start_id..end_id, field => nil).update_all(field => default_value) }
      end
    end
  end
end
