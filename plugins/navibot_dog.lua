-- navibot_dog.lua
-- Sends a random dog picture when a user types /navibot dog in chat.
--
-- Uses on_message (prefix-style) instead of a slash command because
-- the NaviBot Lua API does not expose an HTTP client, so we maintain
-- a curated pool of direct dog image URLs to pick from randomly.
--
-- Drop into your NaviBot `plugins/` folder and reload with `r`.

print("--- Loading Navi Dog Plugin ---")

-- Pool of direct dog image URLs (all from dog.ceo CDN, free to use)
local DOG_IMAGES = {
    "https://images.dog.ceo/breeds/retriever-golden/n02099601_1722.jpg",
    "https://images.dog.ceo/breeds/husky/n02110185_10047.jpg",
    "https://images.dog.ceo/breeds/labrador/n02099712_4323.jpg",
    "https://images.dog.ceo/breeds/poodle-standard/n02113799_3193.jpg",
    "https://images.dog.ceo/breeds/beagle/n02088364_11136.jpg",
    "https://images.dog.ceo/breeds/corgi-cardigan/n02113186_10475.jpg",
    "https://images.dog.ceo/breeds/samoyed/n02111889_4470.jpg",
    "https://images.dog.ceo/breeds/shiba/shiba-7.jpg",
    "https://images.dog.ceo/breeds/akita/Akita_Inu_dog.jpg",
    "https://images.dog.ceo/breeds/dalmatian/cooper2.jpg",
    "https://images.dog.ceo/breeds/dachshund/Dachshund_dealing_with_a_difficult_user.jpg",
    "https://images.dog.ceo/breeds/pug/n02110958_15626.jpg",
    "https://images.dog.ceo/breeds/boxer/n02108089_1.jpg",
    "https://images.dog.ceo/breeds/malamute/n02110063_1104.jpg",
    "https://images.dog.ceo/breeds/chow/n02112137_4558.jpg",
    "https://images.dog.ceo/breeds/collie-border/n02106166_1006.jpg",
    "https://images.dog.ceo/breeds/germanshepherd/n02106662_21120.jpg",
    "https://images.dog.ceo/breeds/setter-irish/n02100877_1141.jpg",
    "https://images.dog.ceo/breeds/spaniel-cocker/n02102318_10430.jpg",
    "https://images.dog.ceo/breeds/terrier-yorkshire/n02094433_2013.jpg",
}

-- Seed random with current time for better randomness
math.randomseed(os.time())

navi.register(function(msg)
    if msg.author_bot then return end

    -- Match "/navibot dog" (case-insensitive, trims extra spaces)
    local trimmed = msg.content:match("^%s*(.-)%s*$")
    if trimmed:lower() == "/navibot dog" then
        local index = math.random(1, #DOG_IMAGES)
        local url = DOG_IMAGES[index]
        navi.say(msg.channel_id, "🐶 Here's your dog!\n" .. url)
    end
end)