// console.time('Execution time took');
chrome.browserAction.setBadgeBackgroundColor({color: [241, 241, 241, 255]});
chrome.browserAction.setBadgeText({text: '...'});
//throw new Error("my error message");
var lang = 'ru';
var staturl = 'https://assa.intertelecom.ua/' + lang + '/statistic/';
//var loginurl = 'https://assa.intertelecom.ua/' + lang + '/login/';

 getPage();
//login();

chrome.alarms.create({'periodInMinutes': 3});
chrome.alarms.onAlarm.addListener(function(alarm) {
  getPage();
});


function parseTraf(txt)  {
    var doc = document.implementation.createHTMLDocument('page');
    doc.documentElement.innerHTML = txt;

    var tables = doc.getElementsByClassName('assa');
    if (!tables.length) {
      return false;
    }

    var sessionRows = tables[0].rows || 0;
    var paketRows = tables[1].rows || 0;
    var paketTraf = 0;

    for (var i = 0, il = sessionRows.length; i < il; i++)
      if (sessionRows[i].cells[0].innerText == 'Трафик МБ') {
          var found = sessionRows[i].cells[1].innerText.replace(/^\s+|\s+$/g, '');
            var sessionTraf = Math.round(found);
        //  console.log('session='+sessionTraf);
            break;
      }

    for (var i = 1, il = paketRows.length; i < il; i++) {
     // if (paketRows[i].cells[0].innerText.indexOf('пакетный трафик') === 0) {
           var found = paketRows[i].cells[1].innerText;
          // if ((/^[0-9]{1,4}\.[0-9]{1,4}$/).test(found))
             paketTraf += parseInt(found);
            // console.log('paket='+paketTraf);
      // }
    }
    return Math.round((paketTraf - sessionTraf) / 10) * 10;
}

function getPage() {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', staturl, true);
    xhr.onload = function(e) {
      if (xhr.readyState === 4) {
        if (xhr.status === 200) {
         //   var location = xhr.getAllResponseHeaders(); //xhr.getResponseHeader('Location');
          //console.log('header:' + location);
             // console.log('200ok ' + xhr.responseText);
             //console.log(xhr.responseURL);
              var currentTraf = parseTraf(xhr.responseText);
              if (!currentTraf) {
                currentTraf = '...';
                var subdomain = xhr.responseURL.indexOf('assa2') != -1 ? 'assa2' : 'assa';
                login(subdomain);
              }
              bt = currentTraf+'';        
              if(currentTraf > 999) {
                chrome.browserAction.setBadgeBackgroundColor({color: [30,132,30,255]});
                bt = Math.round(currentTraf/1024*10)/10 + 'G';
                }
              else if(currentTraf > 100) {
                chrome.browserAction.setBadgeBackgroundColor({color: [30,132,30,255]});
                }
              else {
                chrome.browserAction.setBadgeBackgroundColor({color: [0,0,153,255]}); 
                }    
              chrome.browserAction.setBadgeText({text: bt});
              
        } 
        else {
          console.error('status = ' + xhr.statusText);
        }
      }
    };
    xhr.onerror = function (e) {
        
      console.error('error ' + xhr.statusText);
    };
    xhr.send(null);
}

function login(subdomain) {
    var login = localStorage['login'];
    var password = localStorage['password'];
    if (!login || !password) return;
    
    var xhr = new XMLHttpRequest();
    var params = 'phone='+login+'&pass='+encodeURIComponent(password)+'&ref_link='+encodeURIComponent(staturl)+'&js=1';
    var url = 'https://' + subdomain + '.intertelecom.ua/' + lang + '/login/';

    xhr.open('POST', url, true);
    xhr.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
    xhr.onload = function() {

        if(xhr.readyState == 4 && xhr.status == 200) {
      //   console.log('loginpage = ' + xhr.responseText );
      //getPage();
        }
    }
     xhr.onerror = function (e) {
        
      console.error('error ' + xhr.statusText);
    };
    xhr.send(params);
    
}

// console.timeEnd('Execution time took');

