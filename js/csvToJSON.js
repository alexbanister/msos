const csv = require('csv-parser');
const fs = require('fs');

let prioList = []

fs.createReadStream('masterPrio.tsv')
  .pipe(csv({ separator: '\t' }))
  .on('data', (row) => {
    if(row.special) {
      row.special = true
    } else {
      row.special = false
    }
    if(row.mats) {
      row.mats = true
    } else {
      row.mats = false
    }
    prioList.push(row)
  })
  .on('end', () => {
      console.log(prioList);
    fs.writeFileSync('rawPrioList.json', JSON.stringify(prioList));
  });