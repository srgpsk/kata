// Save this script as `options.js`

// Saves options to localStorage.
function save_options() {
  var login = document.getElementById("login").value;
   var password = document.getElementById("password").value;
  //var color = select.children[select.selectedIndex].value;
  localStorage["login"] = login;
  localStorage["password"] = password;
  // Update status to let user know options were saved.
  var status = document.getElementById("status");
  status.style.color = "green";
  status.innerHTML = "Options Saved.";
  setTimeout(function() {
    status.innerHTML = "";
  }, 750);
}

// Restores select box state to saved value from localStorage.
function restore_options() {
  var login = localStorage["login"];
  var password = localStorage["password"];
  if (!login || !password) {
    return;
  }
  document.getElementById("login").value = login;
  document.getElementById("password").value = password;
}
document.addEventListener('DOMContentLoaded', restore_options);
document.querySelector('#save').addEventListener('click', save_options);
