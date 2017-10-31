module AenSidheBlog
    class PageWithoutAFile < Jekyll::Page
        def read_yaml(*)
            @data ||= {
                "sitemap" => false
            }
        end
    end

    class Sitemap < Jekyll::Generator
        safe true
        priority :lowest

        # Main plugin action, called by Jekyll-core
        def generate(site)
            @site = site
            @site.pages << sitemap unless file_exists?("sitemap.xml")
        end

        private

        INCLUDED_EXTENSIONS = %W(
            .htm
            .html
            .xhtml
            .pdf
        ).freeze

        # Matches all whitespace that follows
        #   1. A '>' followed by a newline or
        #   2. A '}' which closes a Liquid tag
        # We will strip all of this whitespace to minify the template
        MINIFY_REGEX = %r!(?<=>\n|})\s+!

        # Array of all non-jekyll site files with an HTML extension
        def static_files
            @site.static_files.select { |file| INCLUDED_EXTENSIONS.include? file.extname }
        end

        def sitemap
            site_map = PageWithoutAFile.new(@site, File.dirname(__FILE__), "", "sitemap.xml")
            site_map.content = File.read(File.expand_path "sitemap.xml", File.dirname(__FILE__)).gsub(MINIFY_REGEX, "")
            site_map.data["layout"] = nil
            site_map.data["static_files"] = static_files.map(&:to_liquid)
            site_map.data["xsl"] = file_exists?("sitemap.xsl")
            posts = @site.categories["blog"].map { |x| {
                "date" => x.date,
                "path" => x.path,
                "languages" => {
                    @site.default_lang => x.permalink
            }}}

            for lang in @site.languages
                unless lang == @site.default_lang
                    for post in posts
                        path = post["path"].gsub(/_posts\/blog\//, "_posts/blog/" + lang + "/")

                        if file_exists? path
                            post["languages"][lang] = post["languages"][@site.default_lang].gsub(/^\/blog\//, "/blog/" + lang + "/")
                        end
                    end
                end
            end
            site_map.data["grouped_posts"] = posts
            site_map
        end

        # Checks if a file already exists in the site source
        def file_exists?(file_path)
            if @site.respond_to?(:in_source_dir)
                File.exist? @site.in_source_dir(file_path)
            else
                File.exist? Jekyll.sanitized_path(@site.source, file_path)
            end
        end
    end
end
