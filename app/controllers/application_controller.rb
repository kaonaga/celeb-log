# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  def content_highlight(post)
    begin
      brand_name = post.brand.name
      brand_phonetic = post.brand.phonetic
      content = post.blog_entry.content
      content.gsub!(/#{brand_name}/, "<strong>#{brand_name}</strong>").gsub!(/#{brand_phonetic}/, "<strong>#{brand_phonetic}</strong>")

      replaced = ""
      content.each do |line|
        unless line == "\r" and line == "\n" and line == "\r\n"
          replaced << line
        end
      end
      post.blog_entry.content = replaced
    rescue => e
      p e
    end
    post
  end

  def content_thumbnail_highlight(posts)
    posts.each do |p|
      begin
        brand_name = p.brand.name
        brand_phonetic = p.brand.phonetic
        content = p.blog_entry.content
        substitute = content.gsub(/#{brand_name}/, "<strong>#{brand_name}</strong>").gsub(/#{brand_phonetic}/, "<strong>#{brand_phonetic}</strong>")

        replaced = ""
        substitute.each do |line|
          if /#{brand_name}/ =~ line or /#{brand_phonetic}/ =~ line
            if line.split(//u).length > 140
              NKF.nkf('-w', line).split(/[…。！？]/).each do |s|
                replaced << s if /#{brand_name}/ =~ s or /#{brand_phonetic}/ =~ s
              end
              # replaced << line.split(//u).slice(0, 140).join
            else
              replaced << line
            end
          end
        end
        p.blog_entry.content = replaced
      rescue => e
        p e
      end
    end
    posts
  end
end
