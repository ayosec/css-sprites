
namespace :css_sprites do

    desc "Updates the CSSSprites index"
    task :update do
        $LOAD_PATH << File.join(File.dirname(__FILE__), "..", "lib")
        require 'css_sprites'
        require 'css_sprites/generator'
        CSSSprites::Generator.update!
    end

end
