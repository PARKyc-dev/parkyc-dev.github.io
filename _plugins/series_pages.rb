# frozen_string_literal: true

module Jekyll
  class SeriesPagesGenerator < Generator
    safe true

    def generate(site)
      posts_by_series = site.posts.docs.select { |post| post.data['series'].is_a?(String) && !post.data['series'].strip.empty? }
                            .group_by { |post| post.data['series'] }
      posts_by_series.each do |name, posts|
        slug = Utils.slugify(name)
        page = PageWithoutAFile.new(site, site.source, "series/#{slug}", 'index.html')
        page.data.merge!('layout' => 'series', 'title' => name, 'series_posts' => posts.sort_by(&:date))
        site.pages << page
      end
    end
  end
end
