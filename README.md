# 96rp_pager
<h2>Upgraded Pager script from tugamars by me, panda :)</h2>
<p>
Everybody is free to use and modify this script!<br>
Credits for the original creator and me would be nice ofc :D<br>
</p>
<p>
This script was made in "NINETY SIX RP" as a mobile phone replacement!<br>
Right now, you can only use it with QBX-Core.<br>
(unless you can code and replace the events)<br>
</p>
<p>
Feel free to join our discord and support us if u want to :)<br>
We dont sell anything and want to offer free scripts in the near future<br>
</p>
<h1><a href="https://discord.gg/96rp">discord.gg/96rp</a></h1>
Current functions:
- can write messages via number or contact name
- can save contacts
- group messages for jobs
- dispatches

Comming soon:
- better code quallity
   

TODO:
- send messages without command
- more sound effects
- more quallity of life functions


<h1>Installation-Instructions</h1>
- download and unpack zip file or clone with git inside your resources folder
- ensure the resource inside your server config
- add pager as a item inside ox_inventory->data->items.lua
- edit config.lua if needed and have fun

<h3>Add this inside items.lua:</h3>
['pager'] = {
label = 'Pager',
client = { event = "96rp-pager:pager:show" }
},
