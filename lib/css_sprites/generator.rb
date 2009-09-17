
require 'RMagick'

module CSSSprites
    module Generator
        extend self

        class BundleFile
            cattr_accessor :file_count
            self.file_count = 0

            attr_accessor :file_name, :y

            def initialize(mimetype)
                @suffix = mimetype.gsub(/^.*\W/, '')
                new
            end

            def new
                close if @draw
                @draw = Magick::Draw.new
                @image_count = @width = @height = @y = 0

                self.class.file_count += 1
                @file_name = "#{CSSSprites.config["file-bundle"] || "css-sprites-image-bundle"}-#{self.class.file_count}.#{@suffix}"
            end

            def close
                bundle = Magick::Image.new(@width, @height) {|image| image.background_color = CSSSprites.config["background-color"] || "#ffff" }

                @draw.draw bundle
                bundle.write(File.join(RAILS_ROOT, "public", "images", file_name))

                @draw = nil
            end

            def add(image)
                new if @image_count > (CSSSprites.config["max-files-per-bundle"] || 75)
                @width = image.columns if image.columns > @width
                @height += image.rows

                @draw.composite 0, @y, 0, 0, image
                @y += image.rows
                @image_count += 1
            end

        end

        def update!
            config = CSSSprites.read_config

            if File.exist?(CSSSprites::IndexFileName)
                index = (Marshal.load(File.read(CSSSprites::IndexFileName)) rescue {})

                bundles = []
                index.each_value do |item|
                    bundles << item[:bundle]
                end

                bundles.uniq.each do |file|
                    file = File.join(RAILS_ROOT, "public", "images", file)
                    File.delete(file) if File.exist?(file)
                end
            end

            # Find all the images
            image_types = find_images(:max_width => (config["max-width"] || 100).to_i,
                                      :max_height => (config["max-height"] || 100).to_i,
                                      :files => (config["files"] || "**/*"))


            index = {}

            # Render the bundle

            image_types.each_pair do |mimetype, images|
                puts "Generating bundle for #{mimetype} (#{images.size} images)"

                bundle = BundleFile.new(mimetype)
                images.each do |file_image, image|
                    index[file_image] = {
                        :x => 0,
                        :y => bundle.y,
                        :width => image.columns,
                        :height => image.rows,
                        :bundle => bundle.file_name
                    }

                    bundle.add image
                end

                bundle.close
            end

            # Dump the index
            File.open(CSSSprites::IndexFileName, "w") {|f| f.write Marshal.dump(index) }
        end


        def find_images(options)
            puts "Reading images..."
            max_width = options[:max_width]
            max_height = options[:max_height]
            root_dir = File.join(RAILS_ROOT, "public", "images")

            image_types = {}

            options[:files].each do |pattern|
                Dir.glob(File.join(root_dir, pattern)).each do |filename|
                    begin
                        image = Magick::Image.read(filename)
                    rescue Magick::ImageMagickError
                        # Ignore this file
                        next
                    end

                    # We have to ignore animated images
                    next if image.size > 1

                    image = image.first

                    # Invalid image
                    next if image.nil? or image.columns > max_width or image.rows > max_height

                    # Register the image
                    filename = filename[(root_dir.size + 1).. -1]
                    image_types[image.mime_type] ||= []
                    image_types[image.mime_type] << [filename, image]
                end
            end

            image_types
        end

    end
end
