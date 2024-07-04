Config = {}

Config.Pager = {
    ["911p"] = {
        title = "Police",
        broadcastToJobs = {
            ["police"]=true,
        },
        broadcastToRoles = nil,
        discordPermissions = nil,
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
        broadcastToRoles = nil,
        discordPermissions = nil,
        jobPermissions = {
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
        broadcastToRoles = nil,
        discordPermissions = nil,
        jobPermissions = {
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
        broadcastToRoles = nil,
        discordPermissions = nil,
        jobPermissions = nil,
        webhooks = {
            ["a"]="<@9189297405006602> new pager received!"
        },
    }
};

Config.Animations = {
    usePager = {
        dict = 'amb@code_human_wander_texting@male@base',--'amb@code_human_wander_texting_fat@male@idle_a',
        name = 'base',
        flag = 59,
        time = -1,
    },
    getPagerOutOfPocket = {
        dict = 'amb@code_human_wander_texting@male@enter',
        name = 'enter',
        flag = 59,
        time = 2200
    },
    putPagerInPocket = {
        dict = 'amb@code_human_wander_texting@male@exit',
        name = 'exit',
        flag = 59,
        time = 2000
    }
}

Config.PagerObj = 'prop_cs_mini_tv'

Config.LogWebhook = "";

-- Ingame limit: 63 characters