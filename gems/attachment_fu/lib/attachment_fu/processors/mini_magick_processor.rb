require 'mini_magick'

module AttachmentFu # :nodoc:
  module Processors
    module MiniMagickProcessor
      def self.included(base)
        base.send :extend, ClassMethods
        base.alias_method_chain :process_attachment, :processing
      end

      module ClassMethods
        # Yields a block containing an MiniMagick Image for the given binary data.
        def with_image(file, &block)
          begin
            binary_data = file.is_a?(MiniMagick::Image) ? file : MiniMagick::Image.from_file(file) unless !Object.const_defined?(:MiniMagick)
          rescue
            # Log the failure to load the image.
            logger.debug("Exception working with image: #{$!}")
            binary_data = nil
          end
          block.call binary_data if block && binary_data
        ensure
          !binary_data.nil?
        end
      end

    protected
      def process_attachment_with_processing
        return unless process_attachment_without_processing
        with_image do |img|
          max_image_size = attachment_options[:thumbnail_max_image_size_pixels]
          raise ThumbnailError.new("source image too large") if max_image_size && img[:width] * img[:height] > max_image_size
          resize_image_or_thumbnail! img
          self.width = img[:width] if respond_to?(:width)
          self.height = img[:height] if respond_to?(:height)
        end if image?
      end

      # Performs the actual resizing operation for a thumbnail
      def resize_image(img, size)
        size = size.first if size.is_a?(Array) && size.length == 1
        img.combine_options do |commands|
          commands.strip unless attachment_options[:keep_profile]

          # gif are not handled correct, this is a hack, but it seems to work.
          if img.output =~ / GIF /
            img.format("png")
          end           
          
          if size.is_a?(Fixnum) || (size.is_a?(Array) && size.first.is_a?(Fixnum))
            if size.is_a?(Fixnum)
              size = [size, size]
              commands.resize(size.join('x'))
            else
              commands.resize(size.join('x') + '!')
            end
          # extend to thumbnail size
          elsif size.is_a?(String) and size =~ /e$/
            size = size.gsub(/e/, '')
            commands.resize(size.to_s + '>')
            commands.background('#ffffff')
            commands.gravity('center')
            commands.extent(size)
          # crop thumbnail, the smart way
          elsif size.is_a?(String) and size =~ /c$/
             size = size.gsub(/c/, '')
            
            # calculate sizes and aspect ratio
            thumb_width, thumb_height = size.split("x")
            thumb_width   = thumb_width.to_f
            thumb_height  = thumb_height.to_f
            
            thumb_aspect = thumb_width.to_f / thumb_height.to_f
            image_width, image_height = img[:width].to_f, img[:height].to_f
            image_aspect = image_width / image_height
            
            # only crop if image is not smaller in both dimensions
            unless image_width < thumb_width and image_height < thumb_height
              command = calculate_offset(image_width,image_height,image_aspect,thumb_width,thumb_height,thumb_aspect)

              # crop image
              commands.extract(command)
            end

            # don not resize if image is not as height or width then thumbnail
            if image_width < thumb_width or image_height < thumb_height                   
                commands.background('#ffffff')
                commands.gravity('center')
                commands.extent(size)
            # resize image
            else
              commands.resize("#{size.to_s}")
            end
          # crop end
          else
            commands.resize(size.to_s)
          end
        end
        self.temp_path = img
      end

      def calculate_offset(image_width,image_height,image_aspect,thumb_width,thumb_height,thumb_aspect)
      # only crop if image is not smaller in both dimensions

        # special cases, image smaller in one dimension then thumbsize
        if image_width < thumb_width
          offset = (image_height / 2) - (thumb_height / 2)
          command = "#{image_width}x#{thumb_height}+0+#{offset}"
        elsif image_height < thumb_height
          offset = (image_width / 2) - (thumb_width / 2)
          command = "#{thumb_width}x#{image_height}+#{offset}+0"

        # normal thumbnail generation
        # calculate height and offset y, width is fixed                 
        elsif (image_aspect <= thumb_aspect or image_width < thumb_width) and image_height > thumb_height
          height = image_width / thumb_aspect
          offset = (image_height / 2) - (height / 2)
          command = "#{image_width}x#{height}+0+#{offset}"
        # calculate width and offset x, height is fixed
        else
          width = image_height * thumb_aspect
          offset = (image_width / 2) - (width / 2)
          command = "#{width}x#{image_height}+#{offset}+0"
        end
        # crop image
        command
      end


    end
  end
end
