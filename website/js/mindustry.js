function mindustry_init() {
  const command_form = document.getElementById('mindustry_form');
  const command_input = document.getElementById('mindustry_command');

  // Connect the command submission
  if(command_input && command_form) {
    command_form.addEventListener('submit', function(){
      let line = document.createElement('p')
      line.innerHTML = '<span class="TERM_FOREGROUND_7_INTENSE">$ </span>' + command_input.value;
      mindustry_output.prepend(line);
      socket.send(command_input.value);
      command_input.value = "";
    });
  }

  // Create WebSocket connection.
  const socket = new WebSocket("ws://192.168.122.229/mindustry")

  // Connection opened
  socket.addEventListener('open', function (event) {
    socket.send('status');
  });

  // Listen for messages
  socket.addEventListener('message', function (event) {
    const mindustry_output = document.getElementById('mindustry_output');
    let line = document.createElement('p')
    line.innerHTML = convertTerminalCodeToHtml(event.data);
    mindustry_output.prepend(line);
  });
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', mindustry_init);
} else {
  mindustry_init();
}
