module ActiveRecord
  module Acts
    module List
      module InstanceMethods
        def compact_list
          list = acts_as_list_class.find(:all, :conditions => "#{scope_condition}").sort_by{|o| o.send(position_column) || SortLast }
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
          list = acts_as_list_class.find(:all, :conditions => "#{scope_condition}").sort_by{|o| o.send(position_column) || SortLast }
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

        def insert_at_position(position, list=nil)
          list ||= acts_as_list_class.find(:all, :conditions => "#{scope_condition}")
          list = list.sort_by{|o| o.send(position_column) || SortLast }
          if self_index = list.index{|o| o.id == self.id}
            list.delete_at(self_index)
          end

          position = position.to_i - 1 # 1-based
          if position >= 0 && position <= list.count
            list.insert(position, self)

            cnt = 1
            updates = []
            list.each_with_index do |obj, idx|
              updates << "WHEN id=#{obj.id} THEN #{cnt}"
              cnt += 1
            end

            acts_as_list_class.update_all("position=CASE #{updates.join(" ")} ELSE 0 END", "#{scope_condition}") unless updates.empty?
            return true
          else
            return false
          end
        end

        def fix_position_conflicts
          list = acts_as_list_class.where(scope_condition).select([:id, position_column.to_sym]).sort_by{|o| [o.send(position_column) || SortLast, o.id] }
          updates = []
          last_position = 0
          list.each do |obj|
            new_position = (obj.position && obj.position > last_position) ? obj.position : last_position + 1
            updates << "WHEN id=#{obj.id} THEN #{new_position}"
            last_position = new_position
          end
          acts_as_list_class.update_all("position=CASE #{updates.join(" ")} ELSE NULL END", scope_condition) unless updates.empty?
        end

      end
    end
  end
end
