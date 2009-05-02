

TemplatesDir = File.join(File.dirname(__FILE__), "templates")

[
    [ "blank.gif", "public/images" ],
    [ "css-sprites.yml", "config" ]
].each do |source, dest|

    dest = File.join(dest, source)
    unless File.exist?(dest)
        puts "Copying #{source} to #{dest}"
        FileUtils.cp(File.join(TemplatesDir, source), dest)
    end

end
