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
<ul>
   <li>can write messages via number or contact name</li>
   <li>can save contacts</li>
   <li>group messages for jobs</li>
   <li>dispatches</li>
</ul>

Comming soon:
<ul>
   <li>better code quallity</li>
</ul>
   

TODO:
<ul>
   <li>send messages without command</li>
   <li>more sound effects</li>
   <li>more quallity of life functions</li>
</ul>


<h1>Installation-Instructions</h1>
<ul>
   <li>download and unpack zip file or clone with git inside your resources folder</li>
   <li>ensure the resource inside your server config</li>
   <li>add pager as a item inside ox_inventory->data->items.lua</li>
   <li>run .sql script with your database software</li>
   <li>edit config.lua if needed and have fun</li>
</ul>

<h3>Add this inside items.lua:</h3>
['pager'] = {<br>
   <div style="tab-size: 5;">label = 'Pager',</div>
   <div style="tab-size: 5;">client = { event = "96rp-pager:pager:show" }</div>
},
