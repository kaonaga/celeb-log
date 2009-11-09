require 'uri'
require 'net/http'
require 'cgi'
require 'rexml/document'
include REXML
require 'uri'
$KCODE = 'UTF8'

class RakutenSearch
  APPLICATION_ID= "Q7ADDn.xg673KTkvXTQGZS6FKEjks315qofsloyKYWwS6RWPXYdgIo_aGWQilPsQUAD81HE-"
  AFFILIATE_ID = "0a279c43.ccc25294.0a279c44.3832c0b8"
  SID = "2606507"
  PID = "878639085"

  ITEM_SEARCH_URL = "http://search.yahooapis.jp/WebSearchService/V1/webSearch?appid=#{APPLICATION_ID}&affiliate_type=vc&affiliate_id=http%3A%2F%2Fck.jp.ap.valuecommerce.com%2Fservlet%2Freferral%3Fsid%3D#{SID}%26pid%3D#{PID}%26vc_url%3D"

  QUERY = "&query="
  CATEGORY_ID = "&category_id="
  BRAND_ID = "&brand_id="
  PRICE_FROM = "&price_from="
  HITS = "&results=10" #default = 10
  SORT = "&sort=#{URI.encode('-sold')}"
  AVAILABILITY = "&availability=1"

  # comply with brand_category and amazon_category
  @@category_hash = {0 => 2494 #レディースファッション
                    }

  class Result
    def initialize(i)
      @item_title = i.text('Title')
      @item_url = i.text('Url')
    end
    attr_reader :item_title, :item_url
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
    category_id = "&category_id=#{@@category_hash[category]}"
    begin
      api_uri = "#{ITEM_SEARCH_URL}#{SORT}#{category_id}#{AVAILABILITY}#{QUERY}" + URI.encode("#{keyword}")
      p api_uri
      body= fetch(api_uri).body
      doc = Document.new(body)
      doc = nil unless doc.elements['ResultSet/']
    rescue => e
      p e
    end
    if doc
      doc.elements['ResultSet'].elements.each{ |e|
        yield e
      }
    end
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

RakutenSearch.item_search(0, "プラダ")