import * as fs from 'fs';
fs.readFile('./results.json', 'utf8', function(err, data){
    const punks = JSON.parse(data);
    let ids = [];
    for(let i=0; i < punks.length; i++) {
         ids.push(punks[i].name);
    }
    
    fs.writeFile('./onlyNames.json', JSON.stringify(ids), err => {
        if (err) {
          console.error(err);
        }
        // file written successfully
      });
});


  