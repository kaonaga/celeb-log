# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  # require 'uri'

  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  def content_thumbnail_highlight(post)
    begin
      brand_name = post.brand.name
      brand_phonetic = post.brand.phonetic
      content = post.blog_entry.content

      content = trim_content(content, brand_name, brand_phonetic, 140)
      post.blog_entry.content = content.gsub(/#{brand_name}/, "<strong>#{brand_name}</strong>").gsub(/#{brand_phonetic}/, "<strong>#{brand_phonetic}</strong>")
    rescue => e
      p e
    end
    post
  end

  def content_tweet_highlight(posts)
    posts.each do |p|
      begin
        brand_name = p.brand.name
        brand_phonetic = p.brand.phonetic
        content = p.blog_entry.content

        replaced = ""
        content.each do |line|
          if /#{brand_name}/ =~ line or /#{brand_phonetic}/ =~ line
            if line.split(//u).length > 140
              NKF.nkf('-w', line).split(/[…。！？\ ]/).each do |s|
                replaced << trim_content(line, brand_name, brand_phonetic) if /#{brand_name}/ =~ s or /#{brand_phonetic}/ =~ s
              end
            else
              replaced << line
            end
          end
        end
        # escape the replaced content
        p.blog_entry.content = replaced.gsub(/#{brand_name}/, "<strong>#{brand_name}</strong>").gsub(/#{brand_phonetic}/, "<strong>#{brand_phonetic}</strong>")
      rescue => e
        p e
      end
    end
    posts
  end

  def trim_content(content, name, phonetic, limit = 70)
    content_length = content.split(//u).length
    if /#{name}/ =~ content
      res1 = (content_length * (content.index("#{name}").to_f / content.length)).floor
      keyword_index = res1.floor
    else res2 = (content_length * (content.index("#{phonetic}").to_f / content.length)).floor
      keyword_index = res2.floor
    end
    if keyword_index - limit < 0
      index_start = 0
    else
      index_start = keyword_index.to_i - limit
    end
    index_end = limit * 2
    # if index_end > content_length
    #   index_end = content_length - (content_length - keyword_index)/2
    # end

    if index_start == 0
      content = content.split(//u).slice(index_start, index_end).join + "..."
    else
      content = "..." + content.split(//u).slice(index_start, index_end).join + "..."
    end
    content
  end
end
