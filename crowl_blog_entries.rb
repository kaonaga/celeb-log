#!/opt/local/bin/ruby

require 'net/http'
# require 'open-uri'
require 'cgi'
require 'mysql'
require 'dbi'

mysql_host = 'localhost'
mysql_user = 'mysql'
mysql_password = 'mysqlclient'
mysql_db = 'celeb-log_development'

object = Mysql::new(mysql_host, mysql_user, mysql_password, mysql_db)
res = object.query("select id, uri, last_update from blogs")

while res_hash = res.fetch_hash
  res_uri = res_hash["uri"]
  # if res_uri is described in sub domein, convert the uri
  # ex. http://aizawa-sayo.ameblo.jp/
  if res_uri.scan(/http:\/\/([^.]+?).ameblo.jp/) != []
    res_uri = "http://ameblo.jp/" + res_uri.scan(/http:\/\/([^.]+?).ameblo.jp/)[0][0]
  end
  res_uri_hash = res_uri.scan(/http:\/\/(.+?)\/(.+)/)
  host = res_uri_hash[0][0]
  directory_path = res_uri_hash[0][1]

  # page number to crowl
  i = 1
  # flag to decide whether to crowl the next page or not
  next_page_flg = 1

  while next_page_flg
    # whether res_uri ends with '/' or not
    if res_uri.index("/", -1)
      index_path = "page-#{i}.html"
    else
      index_path = "/page-#{i}.html"
    end

    begin
      # connect to the web server
      http = Net::HTTP.new(host)
      # get response from the web server(header and body)
      request_path = "/" + directory_path + index_path
      header,body = http.get(request_path)

      # start debug
      puts "\r\n\r\n"
      p res_hash["id"]
      p res_uri
      p res_uri_hash
      p host
      p request_path
      puts "\r\n"
      # end debug

      # see whether to crowl the next page or not
      if body.scan(/class="nextPage"/) == []
        next_page_flg = nil
      else
        i += 1
      end

      # if j == 0, it means that article is the latest one
      j = 0
      # crowler format settings
      body_scan_res_1 = body.scan(/<span class="date">(.+?)<\/span>.*?<h3 class="title">(.+?)<\/h3>.+?<div class="subContents">(.+?)<!--entryBottom-->.+?<div class="foot">.*?<a href="(.+?)">記事URL<\/a>/m)
      if body_scan_res_1 != []
        match = body_scan_res_1
        match_type = 1
      else
        body_scan_res_2 = body.scan(/<span class="date">(.+?)<\/span>.*?<h3 class="title">(.+?)<\/h3>.+?<div class="subContents">(.+?)<div id="themeBox">.+?<div class="foot">.*?<a href="(.+?)">記事URL<\/a>/m)
        if body_scan_res_2 != []
          match = body_scan_res_2
          match_type = 2
        else
          body_scan_res_3 = body.scan(/<h3 class="title">(.+?)<\/h3>.+?<span class="date">(.+?)<\/span>.*?<div class="subContents">(.+?)<!--entryBottom-->.+?<div class="foot">.*?<a href="(.+?)">記事URL<\/a>/m)
          if body_scan_res_3 != []
            match = body_scan_res_3
            match_type = 3
          end
        end
      end
      match.each do |m|
        if match_type == 1 or match_type == 2
          date = m[0]
          title = m[1].gsub(/<!--.+?-->/m, "").gsub("'", "''")
          content = m[2].gsub(/<!--.+?-->/m, "").gsub("'", "''")
          uri = m[3]
        elsif match_type == 3
          title = m[0].gsub(/<!--.+?-->/m, "").gsub("'", "''")
          date = m[1]
          content = m[2].gsub(/<!--.+?-->/m, "").gsub("'", "''")
          uri = m[3]
        end

        # start debug
        p date
        p title
        p content
        p uri
        if next_page_flg == 1
          puts "crowl next page"
        else
          puts "stop crowl this blog"
        end
        # end debug

        if object.query("select uri from blog_entries where blog_id = #{res_hash['id']} and uri = '#{uri}'").fetch_hash.nil?
          # start debug
          puts "insert into blog_entries (blog_id, title, content, uri, update_date, created_at, updated_at) values('#{res_hash['id']}', '#{title}', '#{content}', '#{uri}', '#{date}', '#{date}', '#{date}')"
          # end debug
          object.query("insert into blog_entries (blog_id, title, content, uri, update_date, created_at, updated_at) values('#{res_hash['id']}', '#{title}', '#{content}', '#{uri}', '#{date}', '#{date}', '#{date}')")

          # start debug
          puts "insert into blog_entries (blog_id, title, content, uri, update_date, created_at, updated_at) values('#{res_hash['id']}', '#{title}', '#{content}', '#{uri}', '#{date}', '#{date}', '#{date}')"
          # end debug

          if j == 0
            object.query("update blogs set last_update = '#{date}' where id = '#{res_hash['id']}'")

            # start debug
            puts "update blogs set last_update = '#{date}' where id = '#{res_hash['id']}'"
            # end debug

          end
        else
          # for only the latest post
          next_page_flg = nil
          break
          # for all posts
          # next
        #   object.query("update blogs set author = '#{author}', phonetic = '#{phonetic}', title = '#{title}', uri = '#{uri}', tags = '#{tags}', crowl_type = '#{crowl_type}', updated_at = '#{time}' where uri = '#{uri}'")
        end
        j += 1
      end
      sleep 0.5
      # for only the latest post
      next_page_flg = nil
    rescue
      p @error
      next_page_flg = nil
    end
  end
end

object.close