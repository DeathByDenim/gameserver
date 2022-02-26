function createConsole(root, game_name, text_colour_function, initial_command) {
  const header = document.createElement('h4');
  const output = document.createElement('div');
  const output_text = document.createElement('p');
  const input = document.createElement('form');
  const input_text = document.createElement('input');
  const input_submit = document.createElement('button');

  header.innerText = game_name[0].toUpperCase() + game_name.substr(1);
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

  root.appendChild(header);
  output.appendChild(output_text);
  root.appendChild(output);
  input.appendChild(input_text);
  input.appendChild(input_submit);
  root.appendChild(input);

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
  // const socket = new WebSocket("wss://DOMAINNAME/" + game_name)
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

}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', consoles_init);
} else {
  consoles_init();
}
