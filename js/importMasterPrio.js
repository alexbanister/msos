const fs = require('fs');
const prioList = require('./rawPrioList.json');

let lua = "defaultPrio = {\n"
prioList.forEach(i => {
    lua += `\t["${i.name}"] = {\n`
    lua += `\t\titemId=${i.itemId},\n`
    lua += `\t\tname="${i.name}",\n`
    lua += `\t\tmats=${i.mats || false},\n`
    lua += `\t\tspecial=${i.special || false},\n`
    lua += `\t\tprio="${i.prio}",\n`
    lua += `\t},\n`
    if (i.prio.length>3) {
        console.log(i);
    }

})
lua += "}"
fs.writeFileSync('../prioList.lua', lua);