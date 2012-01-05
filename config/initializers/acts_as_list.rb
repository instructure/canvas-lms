module ActiveRecord
  module Acts
    module List
      module InstanceMethods
        def compact_list
          list = acts_as_list_class.find(:all, :conditions => "#{scope_condition}").sort_by{|o| o.send(position_column) || 999999 }
          updates = []
          list.each_with_index do |obj, idx|
            updates << "WHEN id=#{obj.id} THEN #{idx}"
          end
          acts_as_list_class.update_all("position=CASE #{updates.join(" ")} ELSE 0 END", "#{scope_condition}") unless updates.empty?
        end
        def insert_at_bottom
          insert_at((bottom_position_in_list || -1) + 1)
        end
        def ensure_in_list
          send(position_column) || insert_at_bottom
        end
        def update_order(ids)
          list = acts_as_list_class.find(:all, :conditions => "#{scope_condition}").sort_by{|o| o.send(position_column) || 999999 }
          updates = []
          done_ids = {}
          cnt = 1
          ids.each do |id|
            id = id.to_i
            next unless id > 0
            updates << "WHEN id=#{id} THEN #{cnt}"
            done_ids[id.to_i] = true
            cnt += 1
          end
          list.each_with_index do |obj, idx|
            if !done_ids[obj.id] && obj.send(position_column)
              updates << "WHEN id=#{obj.id} THEN #{cnt}"
              done_ids[obj.id]
              cnt += 1
            end
          end
          acts_as_list_class.update_all("position=CASE #{updates.join(" ")} ELSE 0 END", "#{scope_condition}") unless updates.empty?
        end
      end
    end
  end
end
