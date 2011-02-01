if Rails::VERSION::MAJOR == 3 && Rails::VERSION::MINOR >= 1
  raise "This patch has been merged into rails 3.1, remove it from our repo"
else
  # bug submitted to rails: https://rails.lighthouseapp.com/projects/8994/tickets/5802-activerecordassociationsassociationcollectionload_target-doesnt-respect-protected-attributes#ticket-5802-1
  # This fix has been merged into rails trunk and will be in the rails 3.1 release.
  class ActiveRecord::Associations::AssociationCollection
    def load_target
      if !@owner.new_record? || foreign_key_present
        begin
          if !loaded?
            if @target.is_a?(Array) && @target.any?
              @target = find_target.map do |f|
                i = @target.index(f)
                if i
                  @target.delete_at(i).tap do |t|
                    keys = ["id"] + t.changes.keys + (f.attribute_names - t.attribute_names)
                    f.attributes.except(*keys).each do |k,v|
                      t.send("#{k}=", v)
                    end
                  end
                else
                  f
                end
              end + @target
            else
              @target = find_target
            end
          end
        rescue ActiveRecord::RecordNotFound
          reset
        end
      end

      loaded if target
      target
    end
  end
end
