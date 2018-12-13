// const rp = require('request-promise');
// const url = {
//   host: 'staugustinechs.netfirms.com',
//   family: 4,
//   port: 80,
//   path: '/stadayonetwo/'
// };

// rp(url)
//   .then(html => {
//     //success!
//     console.log(html);
//     var index = html.lastIndexOf("Day ");
//     var dayNum = html.substring(index+4, index + 5)
//     console.log(dayNum)
    
//     return 0;
//   })
//   .catch(error => {
//     //handle error
//     console.log('error')
//   });

const https = require('https');

const url = {
  host: 'staugustinechs.netfirms.com',
  //port: 8080,
  path: '/stadayonetwo/',
  family: 4
}

https.get(url, (resp) => {
  let data = '';

  // A chunk of data has been recieved.
  resp.on('data', (chunk) => {
    data += chunk;
  });

  // The whole response has been received. Print out the result.
  resp.on('end', () => {
    var index = data.lastIndexOf("Day ");
    var dayNum = data.substring(index+4, index + 5)
    console.log(dayNum)
  });

}).on("error", (err) => {
    console.log("Error: " + err.message);
});