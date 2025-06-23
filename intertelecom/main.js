document.getElementById('phone').innerHTML = '0'+localStorage['login'];

var connA = ["Searching", "Connecting", "Connected", "Disconnecting", "Disconnected", "Not Activated", "Modem Failure", "Dormant", "SIM Failure"]


var xhr = new XMLHttpRequest();
xhr.open("GET", 'http://192.168.1.1/getStatus.cgi?dataType=TEXT', true)
 xhr.onload = function (e) {
    var modem_data = xhr.responseText.split('Ww');
   console.log(modem_data);
   var connection = modem_data[3].split('=');
   var ip = modem_data[7].split('=');
   var connection_status = modem_data[5].split('Ba');
   status_elements = connection_status[0].split('=');
   datavalue = connA[parseInt(status_elements[1])];

    document.getElementById('connection').innerHTML = connection[1];
    document.getElementById('connection_status').innerHTML = datavalue;
    document.getElementById('ip').innerHTML = ip[1];
 }
xhr.send(null);

/*var url = "https://assa.intertelecom.ua/ru/login";
 var phone = "359997644";
 var pass = "password";
 //var phone = localStorage['login'];
 var ref_link = "https://assa.intertelecom.ua/ru/statistic/";
 var js = "1";
 
var xhr = new XMLHttpRequest();

var params = 'phone=' + encodeURIComponent(phone) + 
  '&pass=' + encodeURIComponent(pass) + 
  '&ref_link=' + encodeURIComponent(ref_link) + 
	'&js=' + encodeURIComponent(js);

xhr.open("POST", 'https://assa.intertelecom.ua/ru/login', true)
xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded')

xhr.onreadystatechange = function() {
  if (xhr.readyState == 4) {
    // WARNING! Might be evaluating an evil script!
    var resp = eval("(" + xhr.responseText + ")");
    console.log(resp);
  }
}


xhr.onload = function() {
	chrome.browserAction.setBadgeText({text: "TEST"});
 console.log(this.responseText);
  //alert(this.responseText);

}


xhr.send(params);
*/
  /*  google.load("feeds", "1");

    function initialize() {
      var feed = new google.feeds.Feed("http://feeds.labnol.org/labnol");
      feed.setNumEntries(10);
      var count = 1;
      feed.load(function(result) {
        if (!result.error) {
          var container = document.getElementById("feed");
          var html = "";
          for (var i = 0; i < result.feed.entries.length; i++) {
            var entry = result.feed.entries[i];
            html = "<h5>" + count++ + ". <a href='" + entry.link + "'>" + entry.title + "</a></h5>";
            var div = document.createElement("div");
            div.innerHTML = html;
            container.appendChild(div);            
          }
          document.write(html);
        }
      });
    }
    google.setOnLoadCallback(initialize);

*/
