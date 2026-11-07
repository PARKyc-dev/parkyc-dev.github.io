require 'tmpdir'
require 'fileutils'
require 'nokogiri'
Dir.mktmpdir('series-test-') do |dir|
  %w[_config.yml _layouts _includes _tabs _data assets index.html].each { |path| FileUtils.cp_r(path, dir) if File.exist?(path) }
  FileUtils.mkdir_p("#{dir}/_posts")
  { '2026-01-01-first.md' => "---\ntitle: First\nseries: Test Series\n---\nFirst body", '2026-01-02-second.md' => "---\ntitle: Second\nseries: Test Series\n---\nSecond body", '2026-01-03-alone.md' => "---\ntitle: Alone\n---\nAlone body" }.each { |name, body| File.write("#{dir}/_posts/#{name}", body) }
  raise 'Jekyll build failed' unless system('bundle', 'exec', 'jekyll', 'build', '--source', dir, '--destination', "#{dir}/site", out: File::NULL)
  first = Nokogiri::HTML(File.read("#{dir}/site/posts/first/index.html"))
  alone = Nokogiri::HTML(File.read("#{dir}/site/posts/alone/index.html"))
  listing = Nokogiri::HTML(File.read("#{dir}/site/series/index.html"))
  links = first.css('.series-list a').map(&:text).map(&:strip)
  raise "Series links incorrect: #{links.inspect}" unless links == ['First', 'Second']
  raise 'Current item missing' unless first.at_css('.series-list a[aria-current="page"]')&.text&.strip == 'First'
  raise 'Series shown on standalone post' if alone.at_css('.series-list')
  raise 'Series index missing' unless listing.text.include?('Test Series') && listing.text.include?('Second')
  puts 'Series rendering checks passed'
end
