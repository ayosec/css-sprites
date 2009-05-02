
require 'RMagick'

module CSSSprites
    module Generator
        extend self

        def update!
            config = CSSSprites.read_config

            # Find all the images
            image_types = find_images(:max_width => (config["max-width"] || 100).to_i,
                                      :max_height => (config["max-height"] || 100).to_i,
                                      :files => (config["files"] || "**/*"))


            index = {}

            # Render the bundle
            bundle_dirname = File.join(RAILS_ROOT, "public", "images")
            bundle_filename = config["file-bundle"] || "css-sprites-image-bundle"

            image_types.each_pair {|mimetype, images|
                puts "Generating bundle for #{mimetype} (#{images.size} images)"
                full_file_name = bundle_filename + "." + mimetype.gsub(/^.*\W/, '')

                # Compute the size for the bundle
                width, height = 0, 0
                images.each {|file_image, image|
                    width = image.columns if image.columns > width
                    height += image.rows
                }

                # Copy every image in the bundle
                draw, y = Magick::Draw.new, 0
                images.each {|file_image, image|
                    index[file_image] = {
                        :x => 0,
                        :y => y,
                        :width => image.columns,
                        :height => image.rows,
                        :bundle => full_file_name
                    }

                    draw.composite 0, y, 0, 0, image
                    y += image.rows
                }

                bundle = Magick::Image.new(width, height) {|i| i.background_color = "#000f" }
                draw.draw bundle
                bundle.write(File.join(bundle_dirname, full_file_name))
            }

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
