
require 'uri'

begin
	require 'curb'
rescue LoadError
	warn "You need to install Curb."
end

class WebResource
    
    attr_reader :uri
    attr_reader :response_code, :head_str, :body_str
    
    attr_reader :headers
    attr_reader :age, :content_length, :content_type
    attr_accessor :priority
    
    attr_accessor :text, :dictionary, :multimedia
    attr_accessor :phone_numbers, :emails, :hashtags, :links
    
    def initialize(uri)
        @uri = String.new
        @response_code
        @head_str = String.new
        @body_str = String.new
        
        @headers = Hash.new
        @age = 0
        @content_length = 0
        @content_type
        @priority = 0.0
        
        @text = Array.new
        @dictionary = Hash.new
        @multimedia = Array.new
        
        @phone_numbers = Array.new
        @emails = Array.new
        @hashtags = Array.new
        @links = Array.new
        
        if uri.instance_of? String
            @uri = uri
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
        
        response_code = / \d{3} /.match http_response
        
        if response_code.instance_of? String
            case
            # Success
            when response_code[0] == "2"
                if @headers.has_key? "age"
                    @age = @headers["age"].to_f
                end
                if @headers.has_key? "content-length"
                    @content_length = @headers["content-length"].to_f
                end
            # Redirection
            when response_code[0] == "3"
                if @headers.has_key? "location"
                    @uri = @headers["location"]
                    update_head
                    process_head
                end
            end
        end
    end
    
    def update_body
        puts
        puts("Sending http GET request: " + @uri)
        @body_str = Curl.get(@uri).body_str
    end
    def collect_links
        update_body if @body_str.empty? 
        
        links_tmp = URI.extract(@body_str)
        links_tmp.each do |u|
            uri = URI::parse(u)
            
            hasKnownScheme = false
            URI.scheme_list().each_key do |scheme|
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
                u.strip!
                @links << u
            end
        end
    end
    
    def <=>(other)
        @priority <=> other.priority
    end
end
