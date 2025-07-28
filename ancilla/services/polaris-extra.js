function installLinks() {
  let sidebar = document.querySelector('#vue-container div[data-pw=sidebar] ul');
  if (!sidebar || sidebar.children.length < 4) {
    setTimeout(installLinks, 100);
    return;
  }

  let cl = sidebar.children[0].children[0].getAttribute("class");

  let mpd = document.createElement("li");
  mpd.innerHTML = `
    <a href="http://snapcast.ancilla.ca/mpd" class="${cl}">
      <span class="material-icons-round">speaker</span>
      House Speakers
    </a>
  `;
  sidebar.append(mpd);

  let help = document.createElement("li");
  help.innerHTML = `
    <a href="https://music.ancilla.ca/help.html" class="${cl}">
      <span class="material-icons-round">help</span>
      Help
    </a>
  `;
  sidebar.append(help);
}

window.addEventListener('load', _ => { setTimeout(installLinks, 100); });
