const Database = require('wow-classic-items')
const fs = require('fs');
const prioList = require('./rawPrioList.json');

const items = new Database.Items()
const locations = {
    3456: "Naxx",
    3428: "AQ40",
    3429: "AQ20",
    1977: "ZG",
    2677: "BWL",
    2717: "MC",
    1583: "UBRS",
    2017: "STRAT",
    717: "STOCKS"
}
// const raidItems = items.filter((i) => i.source && i.source.zone && i.source.zone === 3456) //Naxx
// const raidItems = items.filter((i) => i.source && i.source.zone && i.source.zone === 3428) //AQ40
// const raidItems = items.filter((i) => i.source && i.source.zone && i.source.zone === 3429) //AQ20
// const raidItems = items.filter((i) => i.source && i.source.zone && i.source.zone === 1977) //ZG
// const raidItems = items.filter((i) => i.source && i.source.zone && i.source.zone === 2677) //BWL
// const raidItems = items.filter((i) => i.source && i.source.zone && i.source.zone === 2717) //MC
// const raidItems = items.filter((i) => i.source && i.source.zone && i.source.zone === 1583) //UBRS
// const raidItems = items.filter((i) => i.source && i.source.zone && i.source.zone === 2017) //STRAT
// const raidItems = items.filter((i) => i.source && i.source.zone && i.source.zone === 717) //STOCKS
const raidItems = items.filter((i) => (
    i.source && 
    i.source.zone && (
        i.source.zone === 717 ||
        i.source.zone === 2017 ||
        i.source.zone === 1583 ||
        i.source.zone === 2717 ||
        i.source.zone === 2677 ||
        i.source.zone === 1977 ||
        i.source.zone === 3429 ||
        i.source.zone === 3428 ||
        i.source.zone === 3456
    ) && (
        i.quality === 'Legendary' ||
        i.quality === 'Epic' || 
        i.quality === 'Rare'
    )
))

const buildLocation = (item) => {
    let location = {
        from: '',
        location: ''
    }
    if(item.source){
        location.from = item.source.name || "Zone Drop"
    }
    if(item.source && item.source.zone){
        location.location = locations[item.source.zone]
    } 
    return location
}

// const raidItems = items.filter((i) => i.itemId === 22726)
const headers = "itemID, name, from, location, slot, type, special, mats, prio"
let csv = `${headers}\n`
let lua = "local defaultPrio = {\n"
raidItems.forEach(i => {
    // console.log(i);
    const { from, location } = buildLocation(i)
    if (prioList[i.name.toLowerCase()]) {
        i.prio = prioList[i.name.toLowerCase()].prio
        // console.log(i);
    } else {
        i.prio = ' '
    }
    lua += `\t${i.itemId}={\n`
    lua += `\t\titemId=${i.itemId},\n`
    lua += `\t\tname="${i.name}",\n`
    lua += `\t\tmats=${i.mats || false},\n`
    lua += `\t\tspecial=${i.special || false},\n`
    lua += `\t\tprio="${i.prio}",\n`
    lua += `\t},\n`
    csv += `${i.itemId}, ${i.name}, ${from}, ${location}, ${i.class}, ${i.subclass}, ${i.special || ''}, ${i.mats || ''}, ${i.prio}\n`;

})
lua += "}"
fs.writeFileSync('prioList.lua', lua);
fs.writeFileSync('OutputPrio.csv', csv);
console.log("ITEMS:::", raidItems.length);