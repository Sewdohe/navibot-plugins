-- navibot_chat.lua
print("--- Loading Navi Chat Plugin ---")

-- ============================================================
-- HARDCODED CONFIG
-- ============================================================
local GROQ_API_KEY  = "gsk_REPLACE-ME"
local MODEL         = "your-model" --e.g qwen/qwen3-32b
local SYSTEM_PROMPT = "YOUR PROMPT HERE"
-- ============================================================

local function call_groq(prompt)
    if GROQ_API_KEY == "gsk_REPLACE-ME" then
        return "No Groq API key set! Edit GROQ_API_KEY in navibot_chat.lua"
    end

    local safe_system = SYSTEM_PROMPT:gsub('"', '\\"')
    local safe_prompt = prompt:gsub('"', '\\"'):gsub('\n', '\\n')

    local body = '{"model":"' .. MODEL .. '","messages":[{"role":"system","content":"' .. safe_system .. '"},{"role":"user","content":"' .. safe_prompt .. '"}]}'

    local response = navi.http.post(
        "https://api.groq.com/openai/v1/chat/completions",
        body,
        {
            ["Content-Type"]  = "application/json",
            ["Authorization"] = "Bearer " .. GROQ_API_KEY
        }
    )

    if not response then
        return "No response from Groq. Check your network and API key."
    end

    print("navibot raw: " .. tostring(response))

    local text = response:match('"content"%s*:%s*"(.-)"}')
    if not text or text == "" then
        text = response:match('"content"%s*:%s*"(.-)","finish_reason"')
    end

    if not text or text == "" then
        return "Couldn't parse response. Check TUI logs."
    end

    text = text:gsub('\\"', '"'):gsub('\\n', '\n'):gsub('\\t', '\t'):gsub('\\\\', '\\')
    text = text:gsub('\\u003cthink\\u003e.-%\\u003c/think\\u003e', ''):gsub('<think>.+</think>', ''):gsub('^%s+', ''):gsub('%s+$', '')
    return text
end

navi.create_slash("navibot", "Chat with navibot", {
    { name = "ask", description = "Your question for navibot", type = "string", required = true }
},
---@param ctx NaviSlashCtx
function(ctx)
    local prompt = ctx.args.ask
    if not prompt or prompt == "" then
        ctx.reply("Ask me anything! Example: /navibot ask What is the meaning of life?")
        return
    end
    ctx.defer()
    ctx.reply("navibot: " .. call_groq(prompt))
end)

navi.register(function(msg)
    if msg.author_bot then return end
    if not msg.content:lower():match("^navibot%s+") then return end
    local prompt = msg.content:match("^[Bb][Rr][Aa][Ss][Ss][Ee][Ll]%s+(.*)")
    if not prompt or prompt == "" then
        navi.say(msg.channel_id, "Try: navibot [your question]")
        return
    end
    print("navibot: " .. prompt)
    navi.say(msg.channel_id, "navibot: " .. call_groq(prompt))
end)