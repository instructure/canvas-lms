module CanvasExt
  module Marshal
    # load the class if Rails has not loaded it yet
    def load(*args)
      viewed_class_names = []
      
      begin
        super
      rescue ArgumentError => e
        if e.message =~ /undefined class\/module (.+)/
          class_name = $1
          raise e if viewed_class_names.include?(class_name)

          viewed_class_names << class_name
          begin
            retry if class_name.constantize
          rescue
            raise
          end
        else
          raise
        end
      end      
    end
  end  
end

Marshal.singleton_class.prepend(CanvasExt::Marshal)
