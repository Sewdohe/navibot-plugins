-- navibot_roll.lua
-- Adds a /navibot roll command that rolls a die with a specified number of sides.
-- Usage: /navibot roll [sides]

print("--- Loading Navi Roll Plugin ---")

navi.create_slash("navibot", "Roll a die with a custom number of sides", {
    {
        name = "roll",
        description = "Roll a die from 1 to the number you specify",
        type = "integer",
        required = true
    }
}, 
---@param ctx NaviSlashCtx
function(ctx)
    local sides = ctx.args.roll

    -- Validate input
    if sides == nil then
        ctx.reply("⚠️ Please provide the number of sides for your die!")
        return
    end

    if sides < 2 then
        ctx.reply("⚠️ The die must have at least 2 sides!")
        return
    end

    -- Roll the die: random integer from 1 to sides (inclusive)
    math.randomseed(os.time())
    local result = math.random(1, sides)

    ctx.reply("🎲 You rolled a **d" .. sides .. "** and got: **" .. result .. "**!")
end)