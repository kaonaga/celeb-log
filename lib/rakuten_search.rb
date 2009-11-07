require 'net/http'
require 'cgi'
require 'rexml/document'
include REXML
require 'uri'
$KCODE = 'UTF8'

class RakutenSearch
  DEVELOPPER_ID = "44603b9a441d5900a0f5c04f4cfd4b3c"
  AFFILIATE_ID = "0a279c43.ccc25294.0a279c44.3832c0b8"

  HOST = "api.rakuten.co.jp"
  ITEM_SEARCH_URL = "http://api.rakuten.co.jp/rws/2.0/rest?developerId=#{DEVELOPPER_ID}&affiliateId=#{AFFILIATE_ID}&operation=ItemSearch&version=2009-04-15"
  GENRE_SEARCH_URL = "http://api.rakuten.co.jp/rws/2.0/rest?developerId=#{DEVELOPPER_ID}&operation=GenreSearch&version=2007-04-11&genreId="

  HITS = "&hits=10"
  SORT = "&sort=%2BreviewCount"
  IMAGE_FLG = "&imageFlag=1"
  KEYWORD = "&keyword="

  # comply with brand_category and amazon_category
  @@genre_hash = {0 => 100371 #レディースファッション・靴
                }

  class Result
    def initialize(i)
      @item_name = i.text('itemName')
      @item_url = i.text('affiliateUrl')
      @image_url = i.text('mediumImageUrl')
    end
    attr_reader :item_name, :item_url, :image_url
  end

  def self.item_search(category, keyword)
    result = []
    request(category, keyword) do |i|
      result << Result.new(i)
    end
    result
  end

  def self.request(category, keyword)
    doc = nil
    genreid = "&genreId=#{@@genre_hash[category]}"
    begin
      api_uri = "#{ITEM_SEARCH_URL}#{HITS}#{SORT}#{IMAGE_FLG}#{genreid}#{KEYWORD}" + URI.encode("#{keyword}")
      http = Net::HTTP.new("#{HOST}")
      header, body = http.get("#{api_uri.sub("http://#{HOST}", "")}")
      doc = Document.new(body)
      doc = nil unless doc.elements['Response/Body/itemSearch:ItemSearch/Items']
    rescue => e
      p e
    end
    if doc
      doc.elements['Response/Body/itemSearch:ItemSearch/Items'].elements.each{ |e|
        yield e
      }
    end
  end
end