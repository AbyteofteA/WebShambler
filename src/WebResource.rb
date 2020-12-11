
require 'uri'

begin
	require 'curb'
rescue LoadError
	warn "You need to install Curb."
end

class WebResource
    
    attr_reader :uri,
                :base_uri
    attr_reader :response_code,
                :head_str,
                :body_str
    
    attr_reader :headers
    
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
        if uri.is_a? URI::Generic
            @uri = uri.to_s
        end
        @base_uri = URI::Generic.new(uri.scheme, uri.userinfo, uri.host, 
                                     nil, nil, nil, nil, nil, nil).to_s
        @response_code = String.new
        @head_str = String.new
        @body_str = String.new
        
        @headers = Hash.new
        @age = 0
        @content_length = 0
        @content_type
        @priority = 0.0
        
        # Array of paragraphs
        @text = Array.new
        @dictionary = Hash.new
        @multimedia = Array.new
        
        @phone_numbers = Array.new
        @emails = Array.new
        @hashtags = Array.new
        @links = Array.new
    end
    
    def success?
        if @response_code[0] == "2"
            return true
        end
        return false
    end
    def redirect?
        if @response_code[0] == "3"
            return true
        end
        return false
    end
    def error?
        if @response_code[0] == "4" || @response_code[0] == "5"
            return true
        end
        return false
    end
    
    def get_header_fields
        if @headers.instance_of? Hash
            if @headers.has_key? "age"
                @age = @headers["age"].to_f
            else
                @age = 0
            end
            if @headers.has_key? "content-length"
                @content_length = @headers["content-length"].to_f
            else
                @content_length = 0
            end
            if @headers.has_key? "content-type"
                @content_type = @headers["content-type"]
            else
                @content_type = nil
            end
            if @headers.has_key? "content-language"
                @content_language = @headers["content-language"]
            else
                @content_language = nil
            end
            if @headers.has_key? "content-location"
                @content_location = @headers["content-location"]
            else
                @content_location = nil
            end
            if @headers.has_key? "content-md5"
                @content_md5 = @headers["content-md5"]
            else
                @content_md5 = nil
            end
            if @headers.has_key? "content-encoding"
                @content_encoding = @headers["content-encoding"]
            else
                @content_encoding = nil
            end
            if @headers.has_key? "content-disposition"
                @content_disposition = @headers["content-disposition"]
            else
                @content_disposition = nil
            end
            if @headers.has_key? "content-range"
                @content_range = @headers["content-range"]
            else
                @content_range = nil
            end
        end
    end
    
    def update_head
        puts
        puts("Sending http HEAD request: " + @uri)
    
        easy = Curl::Easy.new(@uri) do |c|
            c.head = true 
        end
        easy.perform
        
        @head_str = easy.header_str
    end
    def process_head
        http_response, *http_headers = @head_str.split(/[\r\n]+/).map {|s| s.strip}
        @headers = Hash[http_headers.flat_map do |s| 
            pair = s.scan(/^(\S+): (.+)/)
            pair[-1][0].downcase!
            pair
        end]
        
        @response_code = /[0-9]{3}/.match(http_response).to_s
        
        if success?
            get_header_fields
            return true
        elsif redirect?
            if @headers.has_key? "location"
                @uri = @headers["location"]
                puts " Redirecting... " + @uri
                update_head
                process_head
                return true
            end
        end
        puts " ERROR"
        return false
    end
    
    def update_body
        puts
        puts("Sending http GET request: " + @uri)
        @body_str = Curl.get(@uri).body_str
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
        update_body if @body_str.empty? 
        
        # Collect links using URI.
        
        links_extracted = URI.extract(@body_str)
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
        while index < @body_str.size
            match_data = /href\s*=\s*"([^"]*)"/.match(@body_str, index)
            
            if(!match_data)
                break
            end
            if(!match_data[1])
                break
            end
            
            if appropriate_link? match_data[1]
                new_link = match_data[1]
            else
                new_link = @base_uri + match_data[1]
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
