
require 'uri'

class HTTPResponse
    
    attr_reader :uri,
                :base_uri
                
    attr_reader :head_str, :body_str
    attr_reader :code, :headers
    
    def initialize(uri)
        @uri = uri
        @base_uri = String.new
        
        @head_str = String.new
        @body_str = String.new
        
        @code = String.new
        @headers = Hash.new
    end
    
    def parse_base_uri(uri_str)
        if uri_str.instance_of? String
            begin
                uri = URI.parse(uri_str)
            rescue => ex
                puts "#{ex.class}: #{ex.message}"
            end
            
            return URI::Generic.new(uri.scheme, uri.userinfo, uri.host, 
                                     nil, nil, nil, nil, nil, nil).to_s
        end
    end
    
    def parse(uri, head_str, body_str)
        @uri = uri
        @base_uri = parse_base_uri(uri)
    
        if head_str.instance_of? String
            @head_str = head_str
            
            @code, *@headers = @head_str.split(/[\r\n]+/).map {|s| s.strip}
            @headers = Hash[headers.flat_map do |s| 
                pair = s.scan(/^(\S+): (.+)/)
                pair[-1][0].downcase!
                pair
            end]
            
            @code = /[0-9]{3}/.match(code).to_s
        end
        if body_str.instance_of? String
            @body_str = body_str
        else
            @body_str = String.new
        end
    end
    
    def success?
        if @code[0] == "2"
            return true
        end
        return false
    end
    
    def redirect?
        if @code[0] == "3"
            return true
        end
        return false
    end
    
    def error?
        if @code[0] == "4" || @code[0] == "5"
            return true
        end
        return false
    end
end


