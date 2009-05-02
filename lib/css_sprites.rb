
module CSSSprites

    ConfigFileName = "css-sprites.yml"
    IndexFileName = File.join(RAILS_ROOT, "tmp", "css-sprites-index.marshal")


    def self.read_config
        filename = File.join(RAILS_ROOT, "config", ConfigFileName)
        unless File.exist?(filename)
            STDERR.puts "Error in CSS Sprites: config/#{ConfigFileName} not found."
            return {}
        end

        HashWithIndifferentAccess.new(YAML::load(File.read(filename)))
    end

    mattr_accessor :config
    self.config = read_config

end
