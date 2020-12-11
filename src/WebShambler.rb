
require 'src/WebResource'

class WebShambler
    
    attr_reader :url_regexp
    attr_reader :visitedURLs,
                :frontierURLs
    attr_reader :max_age,
                :max_content_length
    
    def initialize(seed, url_regexp = nil)
        if url_regexp.instance_of? Regexp
            @url_regexp = url_regexp
        end
        @visitedURLs = Array.new
        @frontierURLs = Array.new
        
        @max_age = 0.0
        @max_content_length = 0.0
        
        if seed.instance_of? Array
            seed.each do |uri|
                append_uri(uri)
            end
        end
    end
    
    #
    # I/O methods
    #
    
    def exists?(newURI)
        @frontierURLs.each do |u|
            if u.response.uri == newURI
                return true
            end
        end
        @visitedURLs.each do |u|
            if u.response.uri == newURI
                return true
            end
        end
        return false
    end
    def append_uri(uri_str)
        if uri_str.instance_of? String
            begin
                uri = URI.parse(uri_str)
            rescue => ex
                puts "#{ex.class}: #{ex.message}"
            end
            
            if uri
                if @url_regexp
                    return if !@url_regexp.match? uri_str
                end
                if not exists? uri_str
                    @frontierURLs << WebResource.new(uri_str)
                end
            end
        end
    end
    def get_uri
        uri = @frontierURLs[0]
        if uri
            @frontierURLs = @frontierURLs.drop(1)
            @visitedURLs << uri
            return uri
        end
        return nil
    end
    def show_visited
        puts
        str = "Visited URIs (#{@visitedURLs.size}):"
        puts str
        puts "-" * str.size
        
        @visitedURLs.each do |u|
            p u.response.uri
        end
    end
    def show_frontier
        puts
        str = "Frontier URIs (#{@frontierURLs.size}):"
        puts str
        puts "-" * str.size
        
        @frontierURLs.each do |u|
            puts " [#{u.priority}], \"#{u.response.uri}\""
        end
    end
    
    #
    # Service methods
    #
    
    def update_heads
        @frontierURLs.each do |uri|
        
            uri.update_head
            
            if uri.age > @max_age
                @max_age = uri.age
            end 
            if uri.content_length > @max_content_length 
                @max_content_length = uri.content_length
            end 
        end
    end
    def refresh_priorities
        @frontierURLs.each do |uri_status|
            uri_status.priority = uri_status.age / @max_age
            uri_status.priority *= uri_status.content_length / @max_content_length
        end
    end
    def prioritize
        #frontierURLs.sort!
    end
    def update
        update_heads
        refresh_priorities
        prioritize
    end
    
    def visit
        if resource = get_uri
            
            if not resource.update_head
                return false
            end
            if not resource.update_body
                return false
            end

            resource.collect_links
            
            resource.links.each do |u|
                append_uri(u)
            end
            return true
        else
            return false
        end
    end
end
