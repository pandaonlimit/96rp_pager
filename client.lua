local QBCore = exports['qb-core']:GetCoreObject()

local number = ''
local contacts = {}
local messages = {}
local currentContact = 1
local currentMessage = 1

--------------------------------------------------------------------------
-- Gets pager data from server
--------------------------------------------------------------------------
function GetPagerData()
    QBCore.Functions.TriggerCallback('96rp-pager:server:GetPagerData', function(pagerData)
        number = pagerData.number
        contacts = pagerData.contacts
        messages = pagerData.messages
        currentMessage = #messages
    end)
end


--------------------------------------------------------------------------
-- Returns name or number if no contact found
--------------------------------------------------------------------------
function GetContactFromNumber(number)
    local contact = number
    for key, value in pairs(contacts) do
        if value.number == number then
            return value.name
        end
    end
    return contact
end

--------------------------------------------------------------------------
-- Increases or resets the indexer back to 1
--------------------------------------------------------------------------
function IncreaseIndex(index, tableCount)
    if index < tableCount then
        index = index + 1
    else
        index = 1
    end
    return index
end

--------------------------------------------------------------------------
-- Decreases or sets the indexer to tableCount
--------------------------------------------------------------------------
function DecreaseIndex(index, tableCount)
    if index > 1 then
        index = index - 1
    else
        index = tableCount
    end
    return index
end

--------------------------------------------------------------------------
-- Returns the opposite position of the indexer
--------------------------------------------------------------------------
function GetCurrentIndexReversed(index)
    local half = index / 2
    
    return index
end
--------------------------------------------------------------------------
-- Shows Messages
--------------------------------------------------------------------------
function ShowMessage(message)
    local text = "No Messages found :("
    local contact = ""
    if message then
        contact = GetContactFromNumber(message.number)
        text = string.format("Sender: %s<br>Nr%s: %s", contact, GetCurrentIndexReversed(currentMessage), message.text)
    end
    local showReminder = false
    if message and contact == message.number then
        showReminder = true
    end
    SendNUIMessage({
        showReminder = showReminder,
        text = text,
        action = "pagerShowMessage"
    })
end

--------------------------------------------------------------------------
-- Shows Contact
--------------------------------------------------------------------------
function ShowContact(contact)
    local text = "No Contacts found :("
    local showReminder = false
    if contact then
        text = string.format("Name: %s<br>Number: %s", contact.name, contact.number)
        showReminder = true
    end
    SendNUIMessage({
        showReminder = showReminder,
        text = text,
        action = "pagerShowContact"
    })
    currentMessage = #messages + 1
end

AddEventHandler('QBCore:Client:OnPlayerLoaded', function() 
    GetPagerData()
end)

--------------------------------------------------------------------------
-- Gets triggered, when the resource starts 
-- (examples: player joins server, script restart)
--------------------------------------------------------------------------
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    print("resource started")
    GetPagerData()
end)

--------------------------------------------------------------------------
-- Shows received message when triggered
--------------------------------------------------------------------------
RegisterNetEvent("96rp-pager:pager:received", function(senderNumber, message)
    local contact = GetContactFromNumber(senderNumber)
	table.insert(messages, {
		number = senderNumber,
		text = message
	})
    SendNUIMessage({
        text = string.format("Sender: %s,  </br> %s", contact, message),
        action = "pagerReceived"
    })
end)

--------------------------------------------------------------------------
-- Shows pager when opened 
-- (you need to trigger this event in your inventory system
--  when the pager is used)
--------------------------------------------------------------------------
RegisterNetEvent("96rp-pager:pager:show", function()
    SetNuiFocus(true, true)
    SendNUIMessage({
        text = string.format("Welcome :)<br> Your number: %s", number),
        action = "pagerShowMessageSimple"
    })
    currentMessage = #messages + 1
end)

--------------------------------------------------------------------------
-- Closes pager
--------------------------------------------------------------------------
RegisterNUICallback('dismissPager', function(data, cb)
    SetNuiFocus(false, false)
    cb('')
end)

--------------------------------------------------------------------------
-- Saves or Removes current contact
--------------------------------------------------------------------------
RegisterNUICallback('interactWithContact', function(pagerData, cb)
    print(json.encode(pagerData))
    if pagerData.interaction == "save" then
        local message = messages[currentMessage]
        table.insert(contacts, {
            name = pagerData.value,
            number = message.number
        })
        TriggerServerEvent('96rp-pager:server:SaveContact', pagerData.value, message.number)
        ShowMessage(message)
    elseif pagerData.interaction == "delete" then
        local contact = contacts[currentContact]
        table.remove(contacts, currentContact)
		TriggerServerEvent('96rp-pager:server:RemoveContact', contact.number)
        currentContact = 1
        local contactLeft = nil
        if #contacts > 0 then
            contactLeft = contacts[currentContact]
        end
        ShowContact(contactLeft)
    end
    cb("test")
end)

--------------------------------------------------------------------------
-- Shows Message
--------------------------------------------------------------------------
RegisterNUICallback('showMessageUp', function(data, cb)
    currentMessage = DecreaseIndex(currentMessage, #messages)
    local message = messages[currentMessage]
    ShowMessage(message)
    cb('')
end)

--------------------------------------------------------------------------
-- Shows Message
--------------------------------------------------------------------------
RegisterNUICallback('showMessageDown', function(data, cb)
    currentMessage = IncreaseIndex(currentMessage, #messages)
    local message = messages[currentMessage]
    ShowMessage(message)
    cb('')
end)

--------------------------------------------------------------------------
-- Shows contact
--------------------------------------------------------------------------
RegisterNUICallback('showContactLeft', function(data, cb)
    currentContact = DecreaseIndex(currentContact, #contacts)
    local contact = contacts[currentContact]
    ShowContact(contact)
    cb('')
end)

--------------------------------------------------------------------------
-- Shows contact
--------------------------------------------------------------------------
RegisterNUICallback('showContactRight', function(data, cb)
    currentContact = IncreaseIndex(currentContact, #contacts)
    local contact = contacts[currentContact]
    ShowContact(contact)
    cb('')
end)
--------------------------------------------------------------------------
-- Keyboard interaction for closing pager
--------------------------------------------------------------------------
RegisterKeyMapping('dismisspager', 'Dismiss a pager', 'keyboard', 'x')