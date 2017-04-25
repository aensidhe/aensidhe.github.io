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
            site_map.data["grouped_posts"] = @site
                .collections
                .values
                .select { |x| x.write? }
                .flat_map { |x| x.docs }
                .select { |x| x.data["sitemap"] != false }
                .map { |x| {
                        "lang" => x.permalink[x.permalink.rindex("-")+1..x.permalink.rindex("/")-1],
                        "slug" => x.permalink[0..x.permalink.rindex("-")-1],
                        "post" => x
                } }
                .group_by { |x| x["slug"] }
                .values
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
