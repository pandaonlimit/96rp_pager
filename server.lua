local pagersList = {}

local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function() 
    local citizenId = exports.qbx_core:GetPlayer(source).PlayerData.citizenid
    GetPagerData(citizenId, source)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end
    local players = exports.qbx_core:GetQBPlayers()
    for id, obj in pairs(players)
    do
        local citizenid = exports.qbx_core:GetPlayer(id).PlayerData.citizenid
        GetPagerData(citizenid, id)
    end
end)

function GetNewID(tableName)
    local row = MySQL.single.await('SELECT MAX(id) FROM ' .. tableName)
    local newid = row['MAX(id)']
    if newid ~= nil
    then
        newid = tonumber(newid) + 1
    else
        newid = 0
    end
    return newid
end

function GetNumber(citizenid)
    local usersRow = MySQL.single.await('SELECT number FROM pager_users WHERE citizenid = ?', {citizenid})
    local number = ''
    if usersRow == nil
    then
        local newNumber = CreateRandomNumber()
        MySQL.insert.await('INSERT INTO pager_users (citizenid, number) VALUES (?, ?)', {citizenid, newNumber})
        number = newNumber
    else
        number = usersRow['number']
    end
    return number
end

function GetMessages(citizenid)
    local response = MySQL.query.await('SELECT pager_messages.message as text, pager_users.number FROM pager_messages, pager_messages_users, pager_users WHERE pager_messages_users.user = ? AND pager_messages.id = pager_messages_users.message AND pager_users.citizenid = pager_messages.user', {citizenid})
    return response
end

function GetContacts(citizenid)
    local response = MySQL.query.await('SELECT pager_contacts.name, pager_users.number FROM pager_contacts, pager_contacts_users, pager_users WHERE pager_contacts_users.user = ? AND pager_contacts.id = pager_contacts_users.contact AND pager_users.citizenid = pager_contacts.user', {citizenid})
    return response
end


function GetPagerData(citizenid, serverid)
    local number = GetNumber(citizenid)
    local contacts = GetContacts(citizenid)
    local messages = GetMessages(citizenid)
    pagersList[citizenid] = {
        number = number,
        contacts = contacts,
        messages = messages,
        serverid = serverid
    }
end

--creates a random number for the pager
function CreateRandomNumber()
    local number = ""
    local maxChars = 8
    local count = 1
    
    while count <= maxChars
    do
        number = number ..math.random(9)
        count = count + 1
    end

    return number
end


QBCore.Functions.CreateCallback('96rp-pager:server:GetPagerData', function(source, cb)
    while exports.qbx_core:GetPlayer(source) == nil
    do
        Wait(100)
    end
    local citizenid = exports.qbx_core:GetPlayer(source).PlayerData.citizenid
    while pagersList[citizenid] == nil
    do
        Wait(100)
    end
    cb(pagersList[citizenid])
end)

RegisterCommand("pager", function(source, args, rawCommand)
    local citizenid = exports.qbx_core:GetPlayer(source).PlayerData.citizenid
    local pagerUser = pagersList[citizenid]
    local number = tonumber(args[1])
    if number == nil
    then
        local row = MySQL.single.await('SELECT pager_contacts.user FROM pager_contacts, pager_contacts_users WHERE pager_contacts.name = ? AND pager_contacts_users.user = ? AND pager_contacts.id = pager_contacts_users.contact', {args[1], citizenid})
        if row ~= nil
        then
            number = pagersList[row['user']].number
        end
    end
    local message = args[2]

    for i = 3, #args
    do
        message = message .. " " .. args[i]
    end
    for currentCitizenid, values in pairs(pagersList)
    do
        if values.number == tonumber(number)
        then
            local newID = GetNewID('pager_messages')
            MySQL.insert.await('INSERT INTO pager_messages (id, message, user) VALUES (?, ?, ?)', {newID , message, citizenid})
            MySQL.insert.await('INSERT INTO pager_messages_users (user, message) VALUES (?, ?)', {currentCitizenid, newID})
            TriggerClientEvent('96rp-pager:pager:received', values.serverid, pagerUser.number, message)
        end
    end
end, false)

RegisterNetEvent('96rp-pager:server:SaveContact', function(name, number)
    local src = source
    local newID = GetNewID('pager_contacts')
    local citizenid = exports.qbx_core:GetPlayer(src).PlayerData.citizenid

    local row = MySQL.single.await('SELECT citizenid FROM pager_users WHERE number = ?', {number})
    MySQL.insert.await('INSERT INTO pager_contacts (id, name, user) VALUES (?, ?, ?)', {newID , name, row['citizenid']})
    MySQL.insert.await('INSERT INTO pager_contacts_users (user, contact) VALUES (?, ?)', {citizenid, newID})
end)

RegisterNetEvent('96rp-pager:server:RemoveContact', function(number)
    local src = source
    local citizenid = exports.qbx_core:GetPlayer(src).PlayerData.citizenid

    local contactid = MySQL.single.await('SELECT pager_contacts.id FROM pager_contacts, pager_contacts_users WHERE pager_contacts.id = pager_contacts_users.contact AND pager_contacts_users.user = ? AND  pager_contacts.user = (SELECT citizenid FROM pager_users WHERE number = ?)', {citizenid, number})['id']

    MySQL.single.await('DELETE FROM pager_contacts_users WHERE contact = ?', {contactid})
    MySQL.single.await('DELETE FROM pager_contacts WHERE id = ?', {contactid})
end)

-- function dump(o)
--     if type(o) == 'table' then
--         local s = '{ '
--         for k, v in pairs(o) do
--             if type(k) ~= 'number' then
--                 k = '"' .. k .. '"'
--             end
--             s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
--         end
--         return s .. '} '
--     else
--         return tostring(o)
--     end
-- end

-- local function page(tune,text, src)
--     local pagerTune = Config.Pager[tune];

--     if(pagerTune == nil) then
--         TriggerClientEvent('QBCore:Notify', src, "The paged channel does not exist.", 'error')
--         return false;
--     end

--     local Player = QBCore.Functions.GetPlayer(src)
--     local authorized=false;

--     if pagerTune.jobPermissions ~= nil then
--         for k,v in ipairs(pagerTune.jobPermissions) do
--             if(Player.PlayerData.job.name == v) then
--                 authorized=true;
--                 break
--             end
--         end

--         if authorized == false then
--             TriggerClientEvent('QBCore:Notify', src, "You are not authenticated to broadcast on the paged channel.", 'error');
--             return false;
--         end

--     end

--     if pagerTune.discordPermissions ~= nil then
--         authorized=exports["pv-discord-uac"]:doesUserHaveAnyRole(src,pagerTune.discordPermissions);

--         if authorized == false then
--             TriggerClientEvent('QBCore:Notify', src, "You are not authenticated to broadcast on the paged channel.", 'error');
--             return false;
--         end
--     end
    
--     if pagerTune.jobPermissions == nil and pagerTune.discordPermissions == nil then authorized=true end

--     if authorized then
--         local players = QBCore.Functions.GetQBPlayers()
--         for _, v in pairs(players) do
--             if(pagerTune.broadcastToJobs[v.PlayerData.job.name]) then
--                 if(pagerTune.broadcastToRoles ~= nil) then

--                     if(exports["pv-discord-uac"]:doesUserHaveAnyRole(v.PlayerData.source,pagerTune.broadcastToRoles)) then
--                         TriggerClientEvent("pv-pager:pager:received",  v.PlayerData.source, text);
--                     end

--                 else
--                     TriggerClientEvent("pv-pager:pager:received",  v.PlayerData.source, text);
--                 end

--             end
--         end
--     end

--     for k,v in ipairs(pagerTune.webhooks) do
--         sendToDiscord(k,pagerTune.title,text,v);
--     end

--     sendToDiscord(Config.LogWebhook,pagerTune.title,text, "New pager!",src,true);
-- end

-- QBCore.Commands.Add("page", "Use the pager", {}, false, function(source, args)
--     local src = source

--     local pagerTune = args[1];
--     args[1]="";

--     local text=table.concat(args, " ");

--     page(pagerTune,text,src);
-- end)


-- function sendToDiscord(url,title,text, content,src, admin)
--     local embed = {
--         {
--             ["color"] = 10038562,
--             ["title"] = "Pager - " .. title,
--             ["description"] = text,
--         }
--     }

--     if(admin ~= nil and admin == true) then

--         local discord="";

--         for k, v in pairs(GetPlayerIdentifiers(src)) do
--             if string.sub(v, 1, string.len("discord:")) == "discord:" then
--                 discord = v
--             end
--         end

--         discord = string.gsub(discord, "discord:", "");

--         embed[1].fields = {
--                 {
--                     ["name"]="Sent by",
--                     ["value"]="<@" .. discord .. ">"
--                 }
--         };
--     end

--     PerformHttpRequest(url, function(err, text, headers) end, 'POST', json.encode({username = "Pager", embeds = embed, content = content,}), { ['Content-Type'] = 'application/json' })
-- end