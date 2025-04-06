---@diagnostic disable: lowercase-global, undefined-global

palt(0, false)
palt(1, false)
palt(30, true)
local c, p
local bs
local tiles
local highscore
local time
gamestate = "game"
local olvl = {}
for i = 0, 16 do
    for j = 0, 1024 do
        olvl[i .. "," .. j] = mget(i, j)
    end
end
function resetLevel()
    for i = 0, 16 do
        for j = 0, 1024 do
            mset(i, j, olvl[i .. "," .. j])
        end
    end
end

local savefile = "/appdata/ld57-highscore.pod"
function loadScore()
    highscore = highscore or fetch(savefile) or {}
end

function saveScore(score, time)
    highscore = highscore or {}
    nhighscore = {}
    inserted = false
    for s in all(highscore) do
        if not inserted and score > s.score then
            add(nhighscore, {
                score = score,
                time = math.floor(time * 10) / 10
            })
            inserted = true
        end
        add(nhighscore, s)
    end
    if not inserted then
        add(nhighscore, {
            score = score,
            time = math.floor(time * 10) / 10
        })
    end
    highscore = nhighscore
    store(savefile, highscore)
end

loadScore()

function initGame()
    time = 0
    c = {
        y = 0
    }

    p = {
        tx = 4 * 16,
        x = 4 * 16,
        y = 7 * 16,
        spd = 0,
        maxspd = 0.5,
        acc = 0.05,
        hflip = false,
        monds = 0,
    }

    bs = {}
    tiles = {}
end

initGame()

function updateBullets()
    for b in all(bs) do
        b.x = b.x + b.spd
        tx, ty = (b.x + 8) / 16, (b.y + 8) / 16
        local tile = mget(tx, ty)
        if tile and tile ~= 3 then
            if tile == 33 then
                b.dead = true
                mset(tx, ty, 21)
                visited = {}
                removeneighbours = function(ox, oy)
                    if visited[ox .. "," .. oy] then
                        return
                    end
                    visited[ox .. "," .. oy] = true
                    for x = -1, 1 do
                        for y = -1, 1 do
                            t = mget(ox + x, oy + y)
                            if t == 33 then
                                mset(ox + x, oy + y, 21)
                                removeneighbours(ox + x, oy + y)
                            end
                        end
                    end
                end
                removeneighbours(tx, ty)
            end
            if not b.dead and tile == 21 then
                p.monds += 1
                mset(tx, ty, 3)
            end
            if tile ~= 12 then
                del(bs, b)
            end
        end
    end
end

function updateGame()
    time = time + 1 / 60
    updateBullets()

    if btnp(5) then
        local b = {
            x = p.x,
            y = p.y,
            spd = p.hflip and -8 or 8
        }
        add(bs, b)
    end

    p.y = p.y + p.spd
    p.spd = math.min(p.spd + p.acc, p.maxspd)
    tile = mget((p.x + 8) / 16, (p.y + 8) / 16)
    if tile == 12 or tile == 33 then
        saveScore(p.monds, time)
        gamestate = "gameover"
    elseif tile == 21 then
        mset((p.x + 8) / 16, (p.y + 8) / 16, 3)
        p.monds += 1
    end

    if p.x ~= p.tx then
        if p.x < p.tx then
            p.x = math.min(p.x + 20, p.tx)
        else
            p.x = math.max(p.x - 20, p.tx)
        end
    end


    if btnp(0) then
        p.tx = 4 * 16
        p.hflip = false
    elseif btnp(1) then
        p.tx = 11 * 16
        p.hflip = true
    end
    if btn(3) then
        -- apply boost
        p.y = p.y + p.spd * 4
    end

    local ty = p.y - 64
    c.y = c.y + (ty - c.y) * 0.1
end

function drawGame()
    cls()
    camera(-100, c.y) --math.floor(c.y / 32) * 32)
    map()
    spr(2, p.x, p.y, p.hflip)
    if p.x == 4 * 16 then
        spr(4, 11 * 16, p.y)
    else
        spr(4, 4 * 16, p.y, true)
    end
    for b in all(bs) do
        spr(20, b.x, b.y)
    end

    camera()
    spr(21, 0, 0)
    print("x" .. p.monds, 16, 4)
    -- print("time: " .. math.floor(time * 10) / 10, 0, 16)

    print("hi-score: " .. highscore[1].score, 0, 32)
end

-- Game Over State
function updateGameOver()
    if btnp(5) then
        resetLevel()
        initGame()
        gamestate = "game"
    end
end

function drawGameOver()
    cls()
    drawGame()
    camera()
    print("Game Over", 220, 64, 7)
end

function _update()
    if gamestate == "game" then
        updateGame()
    elseif gamestate == "gameover" then
        updateGameOver()
    end
end

function _draw()
    if gamestate == "game" then
        drawGame()
    elseif gamestate == "gameover" then
        drawGameOver()
    end
end
