
require 'src/HTTPResponse'

require 'uri'

begin
	require 'curb'
rescue LoadError
	warn "You need to install Curb."
end

# 
# HTTP facade for curb.
# 
class HTTPClient

    def self.head(uri)
        puts
        puts("Sending http HEAD request: " + uri)
    
        curl = Curl::Easy.new(uri) do |c|
            c.head = true 
        end
        curl.perform
        
        http_response = HTTPResponse.new(uri)
        http_response.parse(uri, curl.header_str, curl.body_str)
        
        if http_response.success?
            return http_response
        elsif http_response.redirect?
            headers = http_response.headers
            if headers.has_key? "location"
                uri = headers["location"]
                puts " Redirecting... " + uri
                
                return self.head(uri)
            end
        else
            puts " ERROR"
            return nil
        end
    end
    
    def self.get(uri)
        puts
        puts("Sending http GET request: " + uri)
        
        curl = Curl.get(uri)
        
        http_response = HTTPResponse.new(uri)
        http_response.parse(uri, curl.header_str, curl.body_str)
       
        if http_response.success?
            return http_response
        elsif http_response.redirect?
            headers = http_response.headers
            if headers.has_key? "location"
                uri = headers["location"]
                puts " Redirecting... " + uri
                
                return self.get(uri)
            end
        else
            puts " ERROR"
            return nil
        end
    end
end