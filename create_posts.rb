#!/opt/local/bin/ruby

class CreatePosts
  require 'net/http'
  require 'cgi'
  require 'mysql'
  require 'dbi'
  require 'nkf'

  # port = 80
  @@mysql_host = 'localhost'
  @@mysql_user = 'mysql'
  @@mysql_password = 'mysqlclient'
  @@mysql_db = 'celeb-log_development'

  def self.create_posts
    # how many words to get around the keyword
    # content_rangge = 100 #words

    object = Mysql::new(@@mysql_host, @@mysql_user, @@mysql_password, @@mysql_db)
    brand_query = object.query("select id, name, phonetic from brands where delete_flg is null")

    # iteration for brands
    while brand_hash = brand_query.fetch_hash
      brand_id = brand_hash['id']
      name = brand_hash['name']
      phonetic = brand_hash['phonetic']
      escaped_name = name.gsub("'", "''")
      escaped_phonetic = phonetic.gsub("'", "''")

      # start debug
      puts "\r\n#{brand_id}: #{name} (#{phonetic})"
      # end debug

      # iteration for blog entries
      entry_query = object.query("select id, blog_id, content, created_at from blog_entries where content like '%#{escaped_name}%' or content like '%#{escaped_phonetic}%'")
      while entry = entry_query.fetch_hash
        blog_id = entry["blog_id"]
        blog_entry_id = entry["id"]
        content = entry["content"]
        posted_date = entry['created_at']
        time = Date.today.to_s + " " + Time.now.strftime("%X")

        # iteration for search method
        search_method = [name, phonetic].each do |m|
          # skip analyzing for names and phonetics that contain less than 3 words
          if m == name and m.split(//u).length <= 2
            next
          elsif m == phonetic and m.split(//u).length <= 3
            next
          end

          # next_index = 0
          # index = content.index(m, next_index)
          
          # while index
          # start iteration for each line
          # content.each do |line|
            # determin where to start the shorten content
            # content_from = (content.split(//u).length * (index.to_f / content.length)).ceil - content_rangge
            # content_from = 0 if content_from < 0
            # shorten_content = content.split(//u).slice(content_from, content_rangge * 2).join.gsub("'", "''")
            # 
            # content_from = (content.split(//u).length * (next_index.to_f / content.length)).floor
            # content_to = (content.split(//u).length * (index.to_f / content.length)).ceil + m.split(//u).lenght * 2

            # alphabetical keyword search accuracy adjustment
            # ex) if keyword is "ash", except words like "flash"
            if m == name
              # unless /[^a-zA-Z\\\/;:]+#{name}[^a-zA-Z\\\/;:]+/ =~ content.split(//u).slice(content_from, content_to).join.gsub("'", "''")
              unless /[^a-zA-Z\\\/;:]+#{name}[^a-zA-Z\\\/;:]+/ =~ content
                # next_index = index + 1
                # index = content.index("#{name}", next_index)
                # start debug
                puts "=> brand name cannot be specified\r\n"
                # end debug
                next
              end
            end
            # end alphabetical keyword search accuracy adjustment

            if /#{m}/ =~ content
              # do not insert the same post
              if object.query("select id from posts where blog_id = '#{blog_id}' and blog_entry_id = '#{blog_entry_id}' and brand_id = '#{brand_id}'").fetch_hash.nil?
                begin
                  object.query("insert into posts (blog_id, blog_entry_id, brand_id, product_id, posted_date, created_at, updated_at) values(#{blog_id}, #{blog_entry_id}, '#{brand_id}', 'NULL', '#{posted_date}', '#{time}', '#{time}')")
                  # start debug
                  puts "hit by #{m}"
                  # puts "content.length = #{content.length}"
                  # puts "content.split(//u).length = #{content.split(//u).length}"
                  # puts "content_from = #{content_from}"
                  # puts "content_to = #{content_to}"
                  # puts "next_index = #{next_index}"
                  puts "=> 1 row inserted into posts successfully"
                  # end debug
                rescue => error
                  p error
                end
              else
                # start debug
                puts "blog_id = #{blog_id}"
                puts "blog_entry_id = #{blog_entry_id}"
                puts "=> This post has been already created"
                # end debug
              end
            end

            # next_index = index + 1
            # index = content.index("#{name}", next_index)
            # # start debug
            # puts "new next_index = #{next_index}"
            # # end debug
          # end
          # end iteration for each line
        end
        # end iteration for search method
      end
      # end iteration for blog entries

      # set listed_count for brands
      listed_count = object.query("select count(id) count from posts where brand_id = '#{brand_id}' and delete_flg is null").fetch_hash["count"]
      object.query("update brands set listed_count = '#{listed_count}' where id = '#{brand_id}'")

      # start debug
      puts "=> listed_count = #{listed_count}"
      # end debug
    end
    # end iteration for brands
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
        puts "=> brand_id = #{brand_id}: listed_count = #{listed_count}"
        # end debug
      end
    rescue => error
      p error
    end
    object.close
  end
end

CreatePosts.create_posts
CreatePosts.create_blog_listed_count
CreatePosts.create_brand_listed_count