
require 'src/HTTPClient'
require 'src/HTTPResponse'

require 'uri'

class WebResource
    
    attr_reader :response
    
    # Some of HTTP header fields
    attr_reader :age,
                :content_length,
                :content_type, 
                :content_language,
                :content_location,
                :content_md5,
                :content_encoding, 
                :content_disposition,
                :content_range
    
    attr_accessor :priority
    
    # Notes about data that is to be scraped
    attr_accessor :text,
                  :multimedia,
                  :phone_numbers,
                  :emails,
                  :links
    
    def initialize(uri)
        @response = HTTPResponse.new(uri)

        @age = 0
        @content_length = 0
        @content_type = String.new
        @content_language = String.new
        @content_location = String.new
        @content_md5 = String.new
        @content_encoding = String.new 
        @content_disposition = String.new
        @content_range = String.new
        
        @priority = 0.0
        
        @text = Array.new
        @multimedia = Array.new
        @phone_numbers = Array.new
        @emails = Array.new
        @links = Array.new
    end
    
    def update_head
        return @response = HTTPClient.head(@response.uri)
    end
    
    def update_body
        return @response = HTTPClient.get(@response.uri)
    end
    
    def get_header_fields
        headers = @response.headers
        if headers.instance_of? Hash
            if headers.has_key? "age"
                @age = headers["age"].to_f
            else
                @age = 0
            end
            if headers.has_key? "content-length"
                @content_length = headers["content-length"].to_f
            else
                @content_length = 0
            end
            if headers.has_key? "content-type"
                @content_type = headers["content-type"]
            else
                @content_type = nil
            end
            if headers.has_key? "content-language"
                @content_language = headers["content-language"]
            else
                @content_language = nil
            end
            if headers.has_key? "content-location"
                @content_location = headers["content-location"]
            else
                @content_location = nil
            end
            if headers.has_key? "content-md5"
                @content_md5 = headers["content-md5"]
            else
                @content_md5 = nil
            end
            if headers.has_key? "content-encoding"
                @content_encoding = headers["content-encoding"]
            else
                @content_encoding = nil
            end
            if headers.has_key? "content-disposition"
                @content_disposition = headers["content-disposition"]
            else
                @content_disposition = nil
            end
            if headers.has_key? "content-range"
                @content_range = headers["content-range"]
            else
                @content_range = nil
            end
        end
    end
    
    def appropriate_link?(u)
        uri = URI::parse(u)
            
        hasKnownScheme = false
        URI.scheme_list().each_key do |scheme|
            if not uri.scheme
                return false
            end
            if scheme.upcase == uri.scheme.upcase
                hasKnownScheme = true
            end
        end
        
        host = uri.host
        hasHost = false
        if host
            hasHost = true
        end
        
        if hasKnownScheme && hasHost && uri.hierarchical?
            return true
        else
            return false
        end
    end
    
    def collect_links
        update_body if @response.body_str.empty? 
        
        # Collect links using URI.
        
        links_extracted = URI.extract(@response.body_str)
        links_tmp1 = Array.new
        links_extracted.each do |u|
            if appropriate_link? u
                u.strip!
                links_tmp1 << u
            end
        end
        
        # Collect links using Regexp.
        
        links_tmp2 = Array.new
        index = 0
        while index < @response.body_str.size
            match_data = /href\s*=\s*"([^"]*)"/.match(@response.body_str, index)
            
            if(!match_data)
                break
            end
            if(!match_data[1])
                break
            end
            
            if appropriate_link? match_data[1]
                new_link = match_data[1]
            else
                new_link = @response.base_uri + match_data[1]
            end
            links_tmp2 << new_link
            index = match_data.end(1)
        end

        @links = links_tmp1 | links_tmp2
    end
    
    def <=>(other)
        @priority <=> other.priority
    end
end
