  -- trivia.lua
  -- Multiple-choice trivia game. Fetches questions from the Open Trivia Database
  -- (opentdb.com) with a local fallback bank. Tracks wins per user.

  navi.register_config("trivia", {
      { key = "reward_coins",    name = "Coins per Win",
        description = "Coins awarded for a correct answer (requires economy plugin)",
        type = "number",  default = "50"   },
      { key = "timeout_seconds", name = "Question Timeout",
        description = "Seconds players have to answer before the question expires",
        type = "number",  default = "30"   },
      { key = "use_api",         name = "Use Online Questions",
        description = "Fetch from opentdb.com. Disable for offline/local-only mode.",
        type = "boolean", default = "true" },
  })

  -- Config values are stored at config:trivia:<key> by the TUI system.
  -- Since the key contains ":", navi.db.get passes it through without auto-prefixing.
  local function cfg(key)
      return navi.db.get("config:trivia:" .. key)
  end

  -- ─── Fallback question bank ───────────────────────────────────────────────────
  -- Used when use_api=false or the API is unreachable.
  -- Format: q=question, a={answers (4)}, c=correct index (1-based), cat, diff
  local FALLBACK = {
      { q="What is the chemical symbol for gold?",                         a={"Ag","Fe","Au","Gd"},
      c=3, cat="Science",      diff="Easy"   },
      { q="How many bones are in the adult human body?",                   a={"198","206","214","222"},
       c=2, cat="Science",      diff="Medium" },
      { q="What planet is closest to the Sun?",                            a={"Venus","Earth","Mercury","Mars"},
       c=3, cat="Science",      diff="Easy"   },
      { q="What is the powerhouse of the cell?",                           a={"Nucleus","Ribosome","Golgi apparatus","Mitochondria"},
       c=4, cat="Science",      diff="Easy"   },
      { q="Which element has the atomic number 1?",                        a={"Helium","Lithium","Oxygen","Hydrogen"},
       c=4, cat="Science",      diff="Easy"   },
      { q="What is the hardest natural substance on Earth?",               a={"Titanium","Quartz","Diamond","Obsidian"},
       c=3, cat="Science",      diff="Easy"   },
      { q="How many chambers does the human heart have?",                  a={"2","3","4","6"},
       c=3, cat="Science",      diff="Easy"   },
      { q="In what year did World War II end?",                            a={"1943","1944","1945","1946"},
       c=3, cat="History",      diff="Easy"   },
      { q="Who was the first person to walk on the Moon?",                 a={"Buzz Aldrin","Neil Armstrong","Yuri Gagarin","John Glenn"},
        c=2, cat="History",      diff="Easy"   },
      { q="In what year did the Berlin Wall fall?",                        a={"1985","1987","1989","1991"},
       c=3, cat="History",      diff="Medium" },
      { q="Who wrote the Iliad and the Odyssey?",                          a={"Virgil","Plato","Homer","Aristotle"},
       c=3, cat="History",      diff="Medium" },
      { q="The Great Wall of China was primarily built during which dynasty?", a={"Han","Tang","Ming","Qing"},
       c=3, cat="History",      diff="Medium" },
      { q="What is the capital of Australia?",                             a={"Sydney","Melbourne","Perth","Canberra"},
       c=4, cat="Geography",    diff="Medium" },
      { q="What is the longest river in the world?",                       a={"Amazon","Congo","Yangtze","Nile"},
       c=4, cat="Geography",    diff="Easy"   },
      { q="What is the smallest country in the world by area?",            a={"Monaco","San Marino","Vatican City","Liechtenstein"},
       c=3, cat="Geography",    diff="Medium" },
      { q="Which country has the most natural lakes?",                     a={"USA","Russia","Finland","Canada"},
       c=4, cat="Geography",    diff="Hard"   },
      { q="Which desert is the largest in the world (by area)?",           a={"Sahara","Arabian","Gobi","Antarctic"},
       c=4, cat="Geography",    diff="Hard"   },
      { q="What is the tallest mountain in the world?",                    a={"K2","Kangchenjunga","Mount Everest","Lhotse"},
       c=3, cat="Geography",    diff="Easy"   },
      { q="Who co-founded Apple Inc. with Steve Jobs?",                    a={"Bill Gates","Paul Allen","Steve Wozniak","Larry Page"},
       c=3, cat="Technology",   diff="Easy"   },
      { q="In what year was the first iPhone released?",                   a={"2005","2006","2007","2008"},
       c=3, cat="Technology",   diff="Easy"   },
      { q="What programming language was created by Guido van Rossum?",    a={"Java","Ruby","Perl","Python"},
       c=4, cat="Technology",   diff="Easy"   },
      { q="Which band performed 'Bohemian Rhapsody'?",                     a={"Led Zeppelin","The Beatles","Queen","Pink Floyd"},
       c=3, cat="Pop Culture",  diff="Easy"   },
      { q="How many Harry Potter books are in the main series?",           a={"5","6","7","8"},
       c=3, cat="Pop Culture",  diff="Easy"   },
      { q="What country did pizza originate from?",                        a={"Greece","France","Spain","Italy"},
       c=4, cat="Food & Drink", diff="Easy"   },
      { q="What is the main ingredient in traditional guacamole?",         a={"Tomato","Jalapeno","Avocado","Onion"},
       c=3, cat="Food & Drink", diff="Easy"   },
      { q="Which country is famous for inventing sushi?",                  a={"China","Korea","Japan","Thailand"},
       c=3, cat="Food & Drink", diff="Easy"   },
      { q="What is the next prime number after 7?",                        a={"8","9","10","11"},
       c=4, cat="Mathematics",  diff="Easy"   },
      { q="How many sides does a dodecagon have?",                         a={"10","11","12","14"},
       c=3, cat="Mathematics",  diff="Medium" },
      { q="What is the value of Pi to two decimal places?",                a={"3.12","3.14","3.16","3.18"},
       c=2, cat="Mathematics",  diff="Easy"   },
      { q="How many players are on a standard soccer team on the field?",  a={"9","10","11","12"},
       c=3, cat="Sports",       diff="Easy"   },
      { q="How many holes are on a standard golf course?",                 a={"9","12","18","21"},
       c=3, cat="Sports",       diff="Easy"   },
      { q="How many Olympic rings are there?",                             a={"4","5","6","7"},
       c=2, cat="Sports",       diff="Easy"   },
  }

  -- ─── Helpers ──────────────────────────────────────────────────────────────────
  local function urldecode(s)
      -- Decode RFC 3986 percent-encoding returned by opentdb when encode=url3986
      return (s:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
               :gsub("+", " "))
  end

  local function shuffle(t)
      for i = #t, 2, -1 do
          local j = math.random(i)
          t[i], t[j] = t[j], t[i]
      end
      return t
  end

  -- Attempt to fetch one question from the Open Trivia Database.
  -- Returns a normalized question table, or nil on failure.
  local function fetch_api_question()
      local body = navi.http.get("https://opentdb.com/api.php?amount=1&type=multiple&encode=url3986")
      if not body then return nil end

      local ok, data = pcall(navi.json.decode, body)
      if not ok or not data or data.response_code ~= 0 then return nil end

      local r = data.results and data.results[1]
      if not r then return nil end

      -- Build the answer list: correct first (we shuffle below), track the correct text
      local correct_text = urldecode(r.correct_answer)
      local answers = { correct_text }
      for _, wrong in ipairs(r.incorrect_answers or {}) do
          table.insert(answers, urldecode(wrong))
      end
      shuffle(answers)

      -- Find where the correct answer landed after the shuffle
      local correct_idx = 1
      for i, a in ipairs(answers) do
          if a == correct_text then correct_idx = i; break end
      end

      return {
          q    = urldecode(r.question),
          a    = answers,
          c    = correct_idx,
          cat  = urldecode(r.category),
          diff = urldecode(r.difficulty):gsub("^%l", string.upper), -- "easy" -> "Easy"
      }
  end

  -- Pick a question: try the API first, fall back to the local bank.
  local function get_question()
      if cfg("use_api") ~= "false" then
          local q = fetch_api_question()
          if q then return q end
          navi.log("[trivia] API unavailable — using fallback question bank")
      end
      math.randomseed(os.time())
      return FALLBACK[math.random(#FALLBACK)]
  end

  -- ─── Win tracking ─────────────────────────────────────────────────────────────
  -- Wins are stored at the raw key "trivia:wins:<user_id>".
  -- The ":" in the key bypasses navi.db's auto-prefix, giving us full control.
  local function get_wins(user_id)
      return tonumber(navi.db.get("trivia:wins:" .. tostring(user_id))) or 0
  end

  local function add_win(user_id)
      local w = get_wins(user_id) + 1
      navi.db.set("trivia:wins:" .. tostring(user_id), tostring(w))
      return w
  end

  -- ─── Active game state ────────────────────────────────────────────────────────
  -- Keyed by channel_id (always stored as a string for consistency).
  -- { correct_letter, correct_text, timer_id }
  local active_games = {}

  local function end_game(channel_id, timed_out)
      local game = active_games[channel_id]
      if not game then return end     -- guard against double-call
      if game.timer_id then
          navi.clear_interval(game.timer_id)
      end
      active_games[channel_id] = nil

      if timed_out then
          navi.send_message(channel_id, {
              title       = "⏰ Time's Up!",
              description = "Nobody answered in time. The correct answer was **"
                            .. game.correct_text .. "**.",
              color       = 0xFF4444,
          })
      end
  end

  -- ─── Slash Commands ───────────────────────────────────────────────────────────
  navi.create_slash("trivia", "Start a trivia question in this channel", {}, function(ctx)
      local channel_id = tostring(ctx.channel_id) -- normalise to string

      if active_games[channel_id] then
          ctx.reply("⚠️  A question is already active here! Answer it or wait for it to expire.", true)
          return
      end

      -- Defer immediately — the HTTP call below can take up to ~1 second
      ctx.defer(false)

      local q       = get_question()
      local letters = {"A", "B", "C", "D"}

      -- Shuffle a copy of the answers so we don't mutate the fallback bank
      local shuffled = {}
      for i, text in ipairs(q.a) do
          table.insert(shuffled, { text = text, correct = (i == q.c) })
      end
      shuffle(shuffled)

      local correct_letter = ""
      local correct_text   = ""
      local choices        = ""
      for i, entry in ipairs(shuffled) do
          choices = choices .. "**" .. letters[i] .. ")** " .. entry.text .. "\n"
          if entry.correct then
              correct_letter = letters[i]
              correct_text   = entry.text
          end
      end

      local timeout = tonumber(cfg("timeout_seconds")) or 30

      -- Register the game before spawning the timer (closure captures the slot)
      active_games[channel_id] = {
          correct_letter = correct_letter,
          correct_text   = correct_text,
          timer_id       = nil,
      }

      ctx.followup_embed({
          title       = "🎯 " .. q.cat,
          description = "**" .. q.q .. "**\n\n" .. choices,
          color       = 0x5865F2,
          fields = {
              { name = "Difficulty", value = q.diff,         inline = true },
              { name = "Time Limit", value = timeout .. "s", inline = true },
              { name = "Instructions:", value = "Respond with ONLY the letter of your answer!"}
          },
      })

      -- Auto-expire: interval fires once after `timeout` seconds then is cancelled by end_game
      local timer_id = navi.set_interval(function()
          end_game(channel_id, true)
      end, timeout, "s")
      active_games[channel_id].timer_id = timer_id
  end)

  navi.create_slash("trivia_stats", "Check your trivia win count", {}, function(ctx)
      local wins = get_wins(ctx.user_id)
      ctx.reply(string.format(
          "🏆 You have **%d** trivia win%s, %s!",
          wins, wins == 1 and "" or "s", ctx.username
      ), true)
  end)

  navi.create_slash("trivia_top", "Show the trivia leaderboard", {}, function(ctx)
      local rows = navi.db.query(
          "SELECT key, value FROM kv_store WHERE key LIKE 'trivia:wins:%' " ..
          "ORDER BY CAST(value AS INTEGER) DESC LIMIT 5"
      )

      if not rows or #rows == 0 then
          ctx.reply("No wins recorded yet — start a game with `/trivia`!", true)
          return
      end

      local medals = { "🥇", "🥈", "🥉", "4️⃣ ", "5️⃣ " }
      local lines  = {}
      for i, row in ipairs(rows) do
          local user_id = row.key:match("trivia:wins:(.+)")
          local wins    = tonumber(row.value) or 0
          table.insert(lines, string.format(
              "%s <@%s> — **%d win%s**",
              medals[i], user_id, wins, wins == 1 and "" or "s"
          ))
      end

      ctx.reply_embed({
          title       = "🏆 Trivia Leaderboard",
          description = table.concat(lines, "\n"),
          color       = 0xFFD700,
      }, false)
  end)

  -- ─── Message listener (answer detection) ─────────────────────────────────────
  navi.register(function(msg)
      if msg.author_bot then return end

      -- msg.channel_id arrives as u64; normalise to string to match active_games keys
      local channel_id = tostring(msg.channel_id)
      local game = active_games[channel_id]
      if not game then return end

      -- Only recognise a single letter A–D (with optional surrounding whitespace)
      local answer = msg.content:match("^%s*(%a)%s*$")
      if not answer then return end
      answer = answer:upper()
      if answer ~= "A" and answer ~= "B" and answer ~= "C" and answer ~= "D" then return end

      if answer == game.correct_letter then
          local correct_text = game.correct_text
          end_game(channel_id, false)

          local total_wins = add_win(msg.author_id)
          local reward     = tonumber(cfg("reward_coins")) or 50

          navi.send_message(channel_id, {
              title       = "✅ Correct!",
              description = string.format(
                  "🎉 <@%s> got it right!\nThe answer was **%s**.\n\n💰 +%d coins awarded! *(Total wins: %d)*",
                  tostring(msg.author_id), correct_text, reward, total_wins
              ),
              color = 0x57F287,
          })

          navi.emit("economy:add_coins", {
              user_id  = tostring(msg.author_id),
              guild_id = msg.guild_id,
              amount   = reward,
          })
      else
          navi.say(msg.channel_id, string.format("❌ Wrong, <@%s>! Keep trying.", tostring(msg.author_id)))
      end
  end)