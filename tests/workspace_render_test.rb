require 'nokogiri'
page = Nokogiri::HTML(File.read('_site/posts/java-thread/index.html'))
{'.workspace-nav' => 'workspace navigation', '.workspace-path' => 'workspace path', '.workspace-post-type' => 'log type', '.content .code-header button' => 'code copy', '#search-input' => 'search'}.each do |selector, label|
  abort "Missing #{label}" unless page.at_css(selector)
end
puts 'Workspace post checks passed'
