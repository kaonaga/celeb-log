#!/opt/local/bin/ruby

class DestroyNgPosts
  require 'net/http'
  require 'cgi'
  require 'mysql'
  require 'date'
  require 'nkf'
  require 'logger'
  $KCODE = 'UTF8'

  # port = 80
  @@mysql_host = 'localhost'
  @@mysql_user = 'mysql'
  @@mysql_password = 'mysqlclient'
  @@mysql_db = 'celeb-log_development'

  @@logger = Logger.new("/Users/BillEvans/Workspace/celeb-log/log/crowl.log", 'daily')
  # @@logger = Logger.new("/var/www/html/celeb-log/log/crowl.log", 'daily')

  def self.destroy_ng_posts
    object = Mysql::new(@@mysql_host, @@mysql_user, @@mysql_password, @@mysql_db)
    post_query = object.query("select posts.id, blog_entry_id, brand_id, name, phonetic, content, brands.delete_flg from posts 
        inner join brands on posts.brand_id = brands.id 
        inner join blog_entries on posts.blog_entry_id = blog_entries.id 
        where posts.delete_flg is null")
    # start iteration for each post
    while post_hash = post_query.fetch_hash
      post_id = post_hash['id']
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
            ng_flg = analyze_ng_words(brand_id, ng_type, line)
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
  end

  def self.create_blog_listed_count
    object = Mysql::new(@@mysql_host, @@mysql_user, @@mysql_password, @@mysql_db)
    begin
      blog_query = object.query("select id from blogs where delete_flg is null")
      while blog_hash = blog_query.fetch_hash
        blog_id = blog_hash['id']
        listed_count = object.query("select count(id) count from posts where blog_id = #{blog_id} and delete_flg is null").fetch_hash['count']
        object.query("update blogs set listed_count = #{listed_count} where id = #{blog_id}")
        # start debug
        @@logger.debug("=> blog_id = #{blog_id}: listed_count = #{listed_count}")
        puts "=> blog_id = #{blog_id}: listed_count = #{listed_count}"
        # end debug
      end
    rescue => error
      p error
    end
    object.close
  end

  def self.create_brand_listed_count
    object = Mysql::new(@@mysql_host, @@mysql_user, @@mysql_password, @@mysql_db)

    begin
      brand_query = object.query("select id from brands where delete_flg is null")
      while brand_hash = brand_query.fetch_hash
        brand_id = brand_hash['id']
        listed_count = object.query("select count(id) count from posts where brand_id = #{brand_id} and delete_flg is null").fetch_hash['count']
        object.query("update brands set listed_count = '#{listed_count}' where id = '#{brand_id}'")
        # start debug
        @@logger.debug("=> brand_id = #{brand_id}: listed_count = #{listed_count}")
        puts "=> brand_id = #{brand_id}: listed_count = #{listed_count}"
        # end debug
      end
    rescue => error
      p error
    end
    object.close
  end

  def self.analyze_ng_words(brand_id, ng_type, line)
    object = Mysql::new(@@mysql_host, @@mysql_user, @@mysql_password, @@mysql_db)
    ng_flg = nil
    ng_words_query = object.query("select ng_word from ng_words where brand_id = #{brand_id} and ng_type = #{ng_type}")
    unless ng_words_query == []
      # start iteration for each ng_word
      while ng_word = ng_words_query.fetch_hash
        if /(#{ng_word['ng_word']})/ =~ line
          ng_flg = $1
          break
        end
      end
      # end iteration for each ng_word
    end
    object.close
    ng_flg
  end
end

DestroyNgPosts.destroy_ng_posts
DestroyNgPosts.create_blog_listed_count
DestroyNgPosts.create_brand_listed_count