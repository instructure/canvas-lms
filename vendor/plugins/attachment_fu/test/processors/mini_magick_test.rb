require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))

class MiniMagickTest < Test::Unit::TestCase
  attachment_model MiniMagickAttachment

  if Object.const_defined?(:MiniMagick)
    def test_should_resize_image
      attachment = upload_file :filename => '/files/rails.png'
      assert_valid attachment
      assert attachment.image?
      # test MiniMagick thumbnail
      assert_equal 43, attachment.width
      assert_equal 55, attachment.height
      
      thumb      = attachment.thumbnails.detect { |t| t.filename =~ /_thumb/ }
      geo        = attachment.thumbnails.detect { |t| t.filename =~ /_geometry/ }
      
      # test exact resize dimensions
      assert_equal 50, thumb.width
      assert_equal 51, thumb.height
      
      # test geometry string
      assert_equal 31, geo.width
      assert_equal 40, geo.height
    end

    def test_should_crop_image(klass = ImageThumbnailCrop)
      attachment_model klass
      attachment = upload_file :filename => '/files/rails.png'
      assert_valid attachment
      assert  attachment.image?
    #  has_attachment :thumbnails => { :square => "50x50c", :vertical => "30x60c", :horizontal => "60x30c"}

      square      = attachment.thumbnails.detect { |t| t.filename =~ /_square/ }
      vertical    = attachment.thumbnails.detect { |t| t.filename =~ /_vertical/ }
      horizontal  = attachment.thumbnails.detect { |t| t.filename =~ /_horizontal/ }
      
      # test excat resize
      assert_equal 50, square.width
      assert_equal 50, square.height

      assert_equal 30, vertical.width
      assert_equal 60, vertical.height

      assert_equal 60, horizontal.width
      assert_equal 30, horizontal.height
    end
    
    # tests the first step in resize, crop the image in original size to right format
    def test_should_crop_image_right(klass = ImageThumbnailCrop)      
      @@testcases.collect do |testcase| 
        image_width, image_height, thumb_width, thumb_height = testcase[:data]
        image_aspect, thumb_aspect = image_width/image_height, thumb_width/thumb_height
        crop_comand = klass.calculate_offset(image_width, image_height, image_aspect, thumb_width, thumb_height,thumb_aspect)
        # pattern matching on crop command
        if testcase.has_key?(:height) 
          assert crop_comand.match(/^#{image_width}x#{testcase[:height]}\+0\+#{testcase[:yoffset]}$/)
        else 
          assert crop_comand.match(/^#{testcase[:width]}x#{image_height}\+#{testcase[:xoffset]}\+0$/)
        end
      end
    end

  else
    def test_flunk
      puts "MiniMagick not loaded, tests not running"
    end
  end

  @@testcases = [
    # image_aspect <= 1 && thumb_aspect >= 1  
    {:data => [10.0,40.0,2.0,1.0], :height => 5.0, :yoffset => 17.5}, #   1b
    {:data => [10.0,40.0,1.0,1.0], :height => 10.0, :yoffset => 15.0}, #  1b

    # image_aspect < 1 && thumb_aspect < 1
    {:data => [10.0,40.0,1.0,2.0], :height => 20.0, :yoffset => 10.0}, # 1a
    {:data => [2.0,3.0,1.0,2.0], :width => 1.5, :xoffset => 0.25}, # 1a

    # image_aspect = thumb_aspect
    {:data => [10.0,10.0,1.0,1.0], :height => 10.0, :yoffset => 0.0}, # QUADRAT 1c

    # image_aspect >= 1 && thumb_aspect > 1     && image_aspect < thumb_aspect
    {:data => [6.0,3.0,4.0,1.0], :height => 1.5, :yoffset => 0.75}, # 2b  
    {:data => [6.0,6.0,4.0,1.0], :height => 1.5, :yoffset => 2.25}, # 2b  

    # image_aspect > 1 && thumb_aspect > 1     && image_aspect > thumb_aspect
    {:data => [9.0,3.0,2.0,1.0], :width => 6.0, :xoffset => 1.5}, # 2a

    # image_aspect > 1 && thumb_aspect < 1 && image_aspect < thumb_aspect
    {:data => [10.0,5.0,0.1,2.0], :width => 0.25, :xoffset => 4.875}, # 4
    {:data => [10.0,5.0,1.0,2.0], :width => 2.5, :xoffset => 3.75}, # 4

    # image_aspect > 1 && thumb_aspect > 1     && image_aspect > thumb_aspect
    {:data => [9.0,3.0,2.0,1.0], :width => 6.0, :xoffset => 1.5}, # 3a    
    # image_aspect > 1 && thumb_aspect > 1     && image_aspect < thumb_aspect
    {:data => [9.0,3.0,5.0,1.0], :height => 1.8, :yoffset => 0.6} # 3a
  ]





end
