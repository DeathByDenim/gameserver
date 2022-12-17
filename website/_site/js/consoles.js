// Collection of scripts to deploy a server hosting several open-source games
// Copyright (C) 2022  Jarno van der Kolk
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

function createConsole(root, game_name, game_title, text_colour_function, initial_command, help_url, tooltip) {
  const div_card = document.createElement('div');
  const div_card_header = document.createElement('div');
  const h5 = document.createElement('h5');
  const card_button = document.createElement('button');
  const div_collapse = document.createElement('div');
  const div_card_body = document.createElement('div');
  const header = document.createElement('h4');
  const output = document.createElement('div');
  const output_text = document.createElement('p');
  const input = document.createElement('form');
  const input_text = document.createElement('input');
  const input_submit = document.createElement('button');
  const input_help = document.createElement('button');

  div_card.className = "card";
  div_card_header.className = "card-header";
  h5.className = "mb-0";
  card_button.className = "btn btn-link";
  card_button.innerText = game_title;
  div_collapse.className = "collapse";
  div_card_body.className = "card-body";

  output.id = game_name + "_output";
  output.className = "console_output";
  output_text.innerText = game_name + " console";
  input.id = game_name + "_form";
  input.className = "console_form";
  input_text.id = game_name + "_command";
  input_text.className = "console_command";
  input_text.size = 80;
  input_text.autocomplete = "off";
  if(tooltip) {
    input_text.title = tooltip;
  }
  input_submit.id = game_name + "_submit";
  input_submit.className = "console_submit";
  input_submit.innerText = "Enter";
  input_help.id = game_name + "_submit";
  input_help.className = "console_help";
  input_help.innerText = "?";



  root.appendChild(div_card);
  div_card.appendChild(div_card_header);
  div_card_header.appendChild(h5);
  h5.appendChild(card_button);
  div_card.appendChild(div_collapse);
  div_collapse.appendChild(div_card_body);

  output.appendChild(output_text);
  div_card_body.appendChild(output);
  input.appendChild(input_text);
  input.appendChild(input_submit);
  input.appendChild(input_help);
  div_card_body.appendChild(input);

  input_help.addEventListener('click', function(e) {
    e.preventDefault();
    window.open(help_url, '_blank');
  });

  input.addEventListener('submit', function(e){
    e.preventDefault();
    let line = document.createElement('p')
    line.innerText = input_text.value;
    line.className = "user_input";
    output.prepend(line);
    socket.send(input_text.value);
    input_text.value = "";
  });

  // Create WebSocket connection.
  const socket = new WebSocket("ws://192.168.122.44/" + game_name)

  // Connection opened
  socket.addEventListener('open', function (event) {
    socket.send(initial_command);
  });

  socket.addEventListener('error', function (event) {
    console.error(event);
  });

  // Listen for messages
  socket.addEventListener('message', function (event) {
    const output = document.getElementById(game_name + '_output');
    let line = document.createElement('p')
    line.innerHTML = text_colour_function(event.data);
    output.prepend(line);
  });
}

function consoles_init() {
  document.cookie = 'token=MD5GAMEPASSWORD; SameSite=Strict';
  const root = document.getElementById('console-div');
  
  
  createConsole(
    root,
    'armagetron',
    'Armagetron Advanced',
    convertTerminalCodeToHtml,
    'players',
    'http://wiki.armagetronad.org/index.php?title=Console_Commands',
    "Helpful commands:\n• players\tShow current players\n• kick <name>\tKick the player\n• num_ais <num>\tSet the number of AIs for games with more than one player\n• limit_rounds\tEnd the match after this number of rounds\n"
  );
  
  createConsole(
    root,
    'bzflag',
    'Bzflag',
    convertTerminalCodeToHtml,
    '/playerlist',
    'https://wiki.bzflag.org/Slash_Commands',
    "Helpful commands:\n• /playerlist\tDisplay list of players\n• /kick <name>\tKick the player\n• /gameover\tend the current game\n"
  );
  
  createConsole(
    root,
    'mindustry',
    'Mindustry',
    convertTerminalCodeToHtml,
    'status',
    'https://mindustrygame.github.io/wiki/servers/#dedicated-server-commands',
    "Helpful commands:\n• status\tDisplay server status\n• runwave\tTrigger the next wave\n• kick <name>\tKick a person by name\n"
  );
  
  createConsole(
    root,
    'teeworlds',
    'Teeworlds',
    convertTerminalCodeToHtml,
    'status',
    'https://www.teeworlds.com/?page=docs&wiki=server_commands',
    "Helpful commands:\n• status\tDisplay server status\n• change_map <mapname>\tSwitch to <mapname>\n• kick <id>\tKick a person by id\n"
  );
  
  createConsole(
    root,
    'unvanquished',
    'Unvanquished',
    convertDaemonedCodeToHtml,
    '/status',
    'https://wiki.unvanquished.net/wiki/Server/Running#Commands',
    "Helpful commands:\n• /listplayers\tList current players in-game\n• /kick <name>\tKick the player\n• /nextmap\tGo to the next map in the rotation\n"
  );
  
  createConsole(
    root,
    'xonotic',
    'Xonotic',
    convertDaemonedCodeToHtml,
    'who',
    'https://gitlab.com/xonotic/xonotic/-/wikis/Basic-server-configuration',
    "Helpful commands:\n• who\tList current players in-game\n• kick <name>\tKick the player\n• gotomap <name>\tGo to the specified map\n"
  );
  

  collapse_init();
}

function collapse_init() {
  const bars = document.getElementsByClassName('card-header');
  for(let bar of bars) {
    bar.addEventListener('click', function(e) {
      const bartexts = document.getElementsByClassName('collapse');
      for(let bartext of bartexts) {
        bartext.classList.remove("show");
      }
      this.parentElement.children[1].classList.add("show");
    })
  }
  document.getElementsByClassName('collapse')[0].classList.add("show");
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', consoles_init);
} else {
  consoles_init();
}