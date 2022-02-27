function createConsole(root, game_name, text_colour_function, initial_command) {
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

  div_card.className = "card";
  div_card_header.className = "card-header";
  h5.className = "mb-0";
  card_button.className = "btn btn-link";
  card_button.innerText = game_name[0].toUpperCase() + game_name.substr(1);
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
  input_submit.id = game_name + "_submit";
  input_submit.className = "console_submit";
  input_submit.innerText = "Enter";

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
  div_card_body.appendChild(input);

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
  const socket = new WebSocket("wss://DOMAINNAME/" + game_name)

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
  const root = document.getElementById('console-div');
  createConsole(root, 'mindustry', convertTerminalCodeToHtml, 'status');
  createConsole(root, 'unvanquished', convertDaemonedCodeToHtml, '/status');
  createConsole(root, 'xonotic', convertTerminalCodeToHtml, 'who');

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
