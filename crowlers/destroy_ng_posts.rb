#!/opt/local/bin/ruby
# for centos
# /usr/local/bin/ruby

require File.dirname(__FILE__) + "/crowler.rb"

class DestroyNgPosts < Crowler
  def self.destroy_ng_posts
    begin
      # object = Mysql::new(@@mysql_host, @@mysql_user, @@mysql_password, @@mysql_db)
      object = Mysql.init()
      object.options(Mysql::SET_CHARSET_NAME, "utf8")
      object.real_connect(@@mysql_host, @@mysql_user, @@mysql_password, @@mysql_db)

      post_query = object.query("select posts.id, posts.blog_id, blog_entry_id, brand_id, name, phonetic, content, brands.delete_flg from posts 
          inner join brands on posts.brand_id = brands.id 
          inner join blog_entries on posts.blog_entry_id = blog_entries.id 
          where posts.delete_flg is null")
      # start iteration for each post
      while post_hash = post_query.fetch_hash
        post_id = post_hash['id']
        blog_id = post_hash['blog_id']
        blog_entry_id = post_hash['blog_entry_id']
        brand_id = post_hash['brand_id']
        name = post_hash['name']
        phonetic = post_hash['phonetic']
        content = post_hash['content']
        brand_delete_flg = post_hash['brands.delete_flg']

        # start debug
        @@logger.debug("post: #{post_id}, brand:#{brand_id}: #{name} (#{phonetic})")
        puts "post: #{post_id}, brand:#{brand_id}: #{name} (#{phonetic})"
        # end debug

        # whether brand is still available
        unless brand_delete_flg.nil?
          object.query("update posts set delete_flg = 1 where id = #{post_id}")
          # start debug
          @@logger.debug("=> post #{post_id} is destroyed because its brand #{name} is no longer available\r\n\r\n")
          puts "=> post #{post_id} is destroyed because its brand #{name} is no longer available\r\n\r\n"
          # end debug
          next
        end

        # iteration for search method
        search_method = [name, phonetic].each do |m|
          case m
          when phonetic
            ng_type = 0
          when name
            ng_type = 1
          end
          # start iteration for each line
          content.each do |line|
            if /#{m}/ =~ line
              ng_flg = analyze_ng_words(blog_id, brand_id, ng_type, line)
              unless ng_flg.nil?
                object.query("update posts set delete_flg = 1 where id = #{post_id}")
                # start debug
                @@logger.debug("=> post #{post_id} is destroyed because of NG Word #{ng_flg}\r\n\r\n")
                # end debug
                break
              end
            end
          end
          # end iteration for each line
        end
        # end iteration for search method
      end
      # end iteration for each post
      object.close
    rescue => error
      p error
      next_page_flg = nil
    rescue Timeout::Error => error
      p error
      retry
    end
  end

  def self.create_blog_listed_count
    super
  end

  def self.create_brand_listed_count
    super
  end

  def self.analyze_ng_words(blog_id, brand_id, ng_type, line)
    super
  end
end

DestroyNgPosts.destroy_ng_posts
DestroyNgPosts.create_blog_listed_count
DestroyNgPosts.create_brand_listed_count