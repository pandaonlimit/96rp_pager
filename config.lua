Config = {}

Config.Pager = {
    ["911p"] = {
        title = "Police",
        broadcastToJobs = {
            ["police"]=true,
        },
        broadcastToRoles = nil, -- Uses pv-discord-uac; set to nil to ignore
        discordPermissions = nil, -- Uses pv-discord-uac; set to nil to ignore
        jobPermissions = nil,
        webhooks = {
            ["a"]="<@9189297405006602> new pager received!"
        },
    },
    ["policeChat"] = {
        title = "Police",
        broadcastToJobs = {
            ["police"]=true,
        },
        broadcastToRoles = nil, -- Uses pv-discord-uac; set to nil to ignore
        discordPermissions = nil, -- Uses pv-discord-uac; set to nil to ignore
        jobPermissions = { -- set to nil to ignore jobs
            "police"
        },
        webhooks = {
            ["a"]="<@9189297405006602> new pager received!"
        },
    },
    ["medicChat"] = {
        title = "Medic",
        broadcastToJobs = {
            ["ambulance"]=true,
        },
        broadcastToRoles = nil, -- Uses pv-discord-uac; set to nil to ignore
        discordPermissions = nil, -- Uses pv-discord-uac; set to nil to ignore
        jobPermissions = { -- set to nil to ignore jobs
            "ambulance"
        },
        webhooks = {
            ["a"]="<@9189297405006602> new pager received!"
        },
    },
    ["911m"] = {
        title = "Medic",
        broadcastToJobs = {
            ["ambulance"]=true,
        },
        broadcastToRoles = nil, -- Uses pv-discord-uac; set to nil to ignore
        discordPermissions = nil, -- Uses pv-discord-uac; set to nil to ignore
        jobPermissions = nil,
        webhooks = {
            ["a"]="<@9189297405006602> new pager received!"
        },
    }
};

Config.LogWebhook = "";

-- Ingame limit: 63 characters