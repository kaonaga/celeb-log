#!/opt/local/bin/ruby

class CrowlBlogEntries
  require 'uri'
  require 'net/http'
  require 'cgi'
  require 'mysql'
  require 'date'
  require 'nkf'
  $KCODE = 'UTF8'

  @@mysql_host = 'localhost'
  @@mysql_user = 'mysql'
  @@mysql_password = 'mysqlclient'
  @@mysql_db = 'celeb-log_development'

  @@month_hash = {'January' => '01', 
                  'February' => '02', 
                  'March' => '03', 
                  'April' => '04', 
                  'May' => '05', 
                  'June' => '06', 
                  'July' => '07', 
                  'August' => '08', 
                  'September' => '09', 
                  'October' => '10', 
                  'November' => '11', 
                  'December' => '12'
                  }

  @@crowl_type = {'ameblo.jp' => 0, 
                  'www.style-walker.com' => 1, 
                  'www.smooche.jp' => 2
                  }

  def self.crowl_ameblo_entries
    # start iteration for each blog
    blog_query = blog_query(@@crowl_type['ameblo.jp'])
    while blog_hash = blog_query.fetch_hash
      blog_id = blog_hash['id']
      blog_uri = blog_hash['uri']
      crowl_type = 0

      # flag to decide whether to crowl the next page or not
      next_page_flg = 1

      # page number to crowl
      i = 1
      # start iteration for each page
      while next_page_flg
        # whether res_uri ends with '/' or not
        if blog_uri.index("/", -1)
          index_path = "page-#{i}.html"
        else
          index_path = "/page-#{i}.html"
        end

        begin
          body = fetch(blog_uri + index_path).body
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
          # end crowler format settings

          # start iteration for each post
          match.each do |m|
            if match_type == 1 or match_type == 2
              date = m[0]
              title = m[1].gsub(/<.+?>/m, "").gsub("'", "''")
              # content = m[2].gsub(/<.+?>/m, "").gsub("\n", "").gsub("\r", "").gsub("'", "''")
              content = m[2].gsub("<br />", "\n").gsub(/<.+?>/m, "").gsub("'", "''")
              uri = m[3]
            elsif match_type == 3
              title = m[0].gsub(/<.+?>/m, "").gsub("'", "''")
              date = m[1]
              # content = m[2].gsub(/<.+?>/m, "").gsub("\n", "").gsub("\r", "").gsub("'", "''")
              content = m[2].gsub(/<.+?>/m, "").gsub("'", "''")
              uri = m[3]
            end

            # date format modification
            if date =~ /([0-9]+)年([0-9]+)月([0-9]+)日.+? ([0-9]+)時([0-9]+)分([0-9]+)秒/
              date = "#{$1}-#{$2}-#{$3} #{$4}:#{$5}:#{$6}"
            elsif date =~ /([0-9]+)年([0-9]+)月([0-9]+)日/
              date = "#{$1}-#{$2}-#{$3} 00:00:00"
            elsif date =~ /[^,]+, ([a-zA-Z]+) ([0-9]+), ([0-9]+) ([0-9]+):([0-9]+):([0-9]+)/
              # Wed, October 28, 2009 00:23:13
              # 2009-10-29 14:45:41
              month = @@month_hash["#{$1}"]
              date = "#{$3}-#{month}-#{$2} #{$4}:#{$5}:#{$6}"
            elsif date =~ /[^,]+, ([a-zA-Z]+) ([0-9]+), ([0-9]+)/
              # Wed, October 28, 2009
              month = @@month_hash["#{$1}"]
              date = "#{$3}-#{month}-#{$2} 00:00:00"
            elsif date =~ /([a-zA-Z]+) ([0-9]+), ([0-9]+) ([0-9]+):([0-9]+):([0-9]+)/
              # October 28, 2009 23:44:52
              month = @@month_hash["#{$1}"]
              date = "#{$3}-#{month}-#{$2} #{$4}:#{$5}:#{$6}"
            elsif date =~ /([a-zA-Z]+) ([0-9]+), ([0-9]+)/
              # October 28, 2009
              month = @@month_hash["#{$1}"]
              date = "#{$3}-#{month}-#{$2} 00:00:00"
            end
            # end date format modification

            # start debug
            puts "\r\n\r\n"
            puts blog_id
            puts date
            puts title
            puts content
            puts uri
            # end debug

            insert_blog_entry(blog_id, title, content, uri, date)
          end
          # end iteration for each post

          # see whether to crowl the next page or not
          if body.scan(/<a href=".+?" class="nextPage" title="次のページへ">次ページ&nbsp;&gt;&gt;<\/a>/) == []
            next_page_flg = nil
            # start debug
            puts "=> stop crowl this blog"
            # end debug
          else
            i += 1
            # start debug
            puts "=> crowl next page"
            # end debug
          end

          sleep 0.5

          # local test setting
          if i >= 2
            next_page_flg = nil
          end
          # end local test setting

        rescue => error
          p error
          next_page_flg = nil
        rescue Timeout::Error => error
          p error
          retry
        end
      end
      # end itelation for each page
    end
    # end iteration for each blog
  end

  def self.crowl_style_walker_entries
    # start iteration for each blog
    blog_query = blog_query(@@crowl_type['www.style-walker.com'])
    while blog_hash = blog_query.fetch_hash
      blog_id = blog_hash['id']
      blog_uri = blog_hash['uri']
      crowl_type = 1

      # flag to decide whether to crowl the next page or not
      next_page_flg = 1
      # page number to crowl
      i = 0
      # start iteration for each page
      while next_page_flg
        index_path = "&did=0&year=0&month=0&day=0&categoryid=&pno=#{i}"
        begin
          body = fetch(blog_uri + index_path).body
          match = body.scan(/<div class="main_title"><span class="main_titleText s4"><a href="(.+?)" target="subWin" class="main_titleLinkText">(.+?)<\/a><\/span><\/div>.+<div class="main_body"><span class="main_bodyText s3p">(.+?)<\/span><\/div>.+<div class="main_footer"><span class="main_footerText s1m">(.+?)&nbsp;｜&nbsp;カテゴリー：/m)

          # start iteration for each post
          match.each do |m|
            uri = m[0]
            title = m[1].gsub("'", "''")
            # content = m[2].gsub(/<.+?>/m, "").gsub("\n", "").gsub("\r", "").gsub("'", "''")
            content = m[2].gsub(/<.+?>/m, "").gsub("'", "''")
            date = m[3] + ":00"

            # start debug
            puts "\r\n\r\n"
            puts blog_id
            puts date
            puts title
            puts content
            puts uri
            # end debug

            insert_blog_entry(blog_id, title, content, uri, date)
          end
          # end iteration for each post

          # see whether to crowl the next page or not
          if body.scan(/<a href=".+?" class="pagerLink">次へ&gt;&gt;<\/a>/) == []
            next_page_flg = nil
            # start debug
            puts "=> stop crowl this blog"
            # end debug
          else
            i += 1
            # start debug
            puts "=> crowl next page"
            # end debug
          end

          sleep 0.5

          # local test setting
          if i >= 3
            next_page_flg = nil
          end
          # end local test setting

        rescue => error
          p error
          next_page_flg = nil
        rescue Timeout::Error => error
          p error
          retry
        end
      end
      # end iteration for each page
    end
    # end iteration for each blog
  end

  def self.crowl_smooche_entries
    # start iteration for each blog
    blog_query = blog_query(@@crowl_type['www.smooche.jp'])
    while blog_hash = blog_query.fetch_hash
      blog_id = blog_hash['id']
      blog_uri = blog_hash['uri']
      crowl_type = 1

      # start search the latest post
      begin
        body = fetch(blog_uri).body
        match = NKF.nkf('-w', body).scan(/<ul class="subList">.+?<li><a href="(.+?)">(.+?)<\/a><\/li>/m)

        latest_index = match[0][0]
        latest_title = NKF.nkf('-w', match[0][1]).gsub("'", "''")

        # start debug
        puts "latest post title = #{latest_title}"
        puts latest_index
        puts "\r\n"
        # end debug
      rescue => error
        p error
        next_page_flg = nil
      rescue Timeout::Error => error
        p error
        retry
      end
      # end search the latest post

      # flag to decide whether to crowl the next page or not
      next_page_flg = 1
      # page number to crowl
      next_page_uri = latest_index
      # start iteration for each page
      while next_page_flg
        begin
          index_path = next_page_uri
          request_path = blog_uri + index_path
          body = fetch(request_path).body
          # match = body.scan(/<span class="date3">(.+?)\(.+?\) <\/span>/m)
          match = NKF.nkf('-w', body).scan(/<span class="date.+">(.+?)\(.+?\) <\/span>.+?<h3 class="title">(.+?) <\/h3>.+?<p class="news">(.+?)<\/p>.+?<p class="newsFoot">Posted by 梨花 @(.+?)<\/p>/m)

          unless match == []
            uri = request_path
            match[0][0] =~ /([0-9]+)\/([0-9]+)\/([0-9]+)/
            date = "#{$1}-#{$2}-#{$3} " + match[0][3] + ":00"
            title = NKF.nkf('-w', match[0][1]).gsub("'", "''")
            # content = NKF.nkf('-w', match[0][2]).gsub(/<.+?>/m, "").gsub("\n", "").gsub("\r", "").gsub("'", "''")
            content = NKF.nkf('-w', match[0][2]).gsub(/<.+?>/m, "").gsub("'", "''")

            # start debug
            puts blog_id
            puts date
            puts title
            puts content
            puts uri
            # end debug

            insert_blog_entry(blog_id, title, content, uri, date)
          else
            match = NKF.nkf('-w', body).scan(/<span class="date.+">(.+?)\(.+?\) <\/span>.+?<h3 class="title">(.+?) <\/h3>.+?<p class="newsFoot">Posted by 梨花 @(.+?)<\/p>/m)
            unless match == []
              uri = request_path
              match[0][0] =~ /([0-9]+)\/([0-9]+)\/([0-9]+)/
              date = "#{$1}-#{$2}-#{$3} " + match[0][2] + ":00"
              title = NKF.nkf('-w', match[0][1]).gsub("'", "''")

              # start debug
              puts blog_id
              puts date
              puts title
              puts "content is nil"
              puts uri
              # end debug

              insert_blog_entry(blog_id, title, 'NULL', uri, date)
              puts "=> content does not have any text"
            else
              puts "=> content does not match the crowl format"
            end
          end

          # see whether to crowl the next page or not
          result = body.scan(/<ul id="newsNaviBox">.+?<li id="entryBack"><a href="(.+?)">&lt;&lt; (.+?)<\/a>/m)
          if result == []
            next_page_uri = nil
            # start debug
            puts "=> stop crowl this blog\r\n\r\n"
            # end debug
          else
            next_page_uri = result[0][0]
            # start debug
            puts "=> crowl next page: #{blog_uri}#{next_page_uri}\r\n\r\n"
            # end debug
          end

          sleep 0.5

          # local test setting
          # next_page_flg = nil
          # end local test setting

        rescue => error
          p error
          next_page_flg = nil
        rescue Timeout::Error => error
          p error
          retry
        end
      end
      # end iteration for each page
    end
    # end iteration for each blog
  end

  def self.blog_query(crowl_type)
    object = Mysql::new(@@mysql_host, @@mysql_user, @@mysql_password, @@mysql_db)
    blog_query = object.query("select id, uri from blogs where crowl_type = #{crowl_type} and delete_flg is null")
    object.close
    return blog_query
  end

  def self.insert_blog_entry(blog_id, title, content, uri, date)
    object = Mysql::new(@@mysql_host, @@mysql_user, @@mysql_password, @@mysql_db)
    if object.query("select id from blog_entries where blog_id = #{blog_id} and uri = '#{uri}'").fetch_hash.nil?
      object.query("insert into blog_entries (blog_id, title, content, uri, created_at, updated_at) values('#{blog_id}', '#{title}', '#{content}', '#{uri}', '#{date}', '#{date}')")
      # start debug
      puts "=> 1 row inserted nto blog_entries successfully"
      # end debug
      last_update = object.query("select last_update from blogs where id = #{blog_id}").fetch_hash['last_update']
      if Time.local(date) > Time.local(last_update)
        object.query("update blogs set last_update = '#{date}' where id = '#{blog_id}'")
        # start debug
        puts "last_update = #{last_update}"
        puts "this article's published date = #{date}"
        puts "=> update blogs set last_update = '#{date}' where id = '#{blog_id}'"
        # end debug
      end
    else
      # start debug
      puts "=> this article has been already crowled"
      # end debug

      # for only the latest post
      # next_page_flg = nil
      # break
    end
    object.close
  end

  def self.fetch( uri_str, limit = 10 )
    # 適切な例外クラスに変えるべき
    raise ArgumentError, 'http redirect too deep' if limit == 0

    response = Net::HTTP.get_response(URI.parse(uri_str))
    case response
    when Net::HTTPSuccess     then response
    when Net::HTTPRedirection then fetch(response['Location'], limit - 1)
    when Net::HTTPFound       then fetch(response['Location'], limit - 1)
    else
      response.error!
    end
  end
end


CrowlBlogEntries.crowl_ameblo_entries
CrowlBlogEntries.crowl_style_walker_entries
CrowlBlogEntries.crowl_smooche_entries