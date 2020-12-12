
$LOAD_PATH.push '.'

require 'src/WebShambler'

seed = ["https://en.wikipedia.org/wiki/Main_Page"]
spidey = WebShambler.new(seed, /https:\/\/en.wikipedia/)

while spidey.visit
    spidey.update
    ы
    if spidey.frontierURLs.size > 100
        break
    end
end

spidey.show_visited
spidey.show_frontier
    